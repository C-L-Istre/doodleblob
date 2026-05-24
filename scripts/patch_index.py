#!/usr/bin/env python3
"""
Patch the Godot-generated index.html for Lighthouse and PWA compliance.

Usage: python3 patch_index.py <path/to/index.html>

Reads configuration from environment variables set in the workflow:
  THEME_COLOR  — hex colour for theme-color meta tag
  GAME_NAME    — display name used in Open Graph / Twitter meta tags
  GAME_URL     — canonical URL used in meta tags and og:image

Changes applied:
  1. Viewport — removes user-scalable=no (Lighthouse accessibility requirement;
                users must be able to zoom)
  2. Manifest  — removes Godot's index.manifest.json reference; our CI-owned
                manifest.webmanifest is referenced instead
  3. Head injection — manifest link, canonical URL, theme-color, description,
                      Open Graph, and Twitter Card meta tags
  4. Canvas sizing — sets body and #canvas to 100vw/100vh for full-screen layout
  5. Audio unlock — event listener shim that resumes AudioContext on first user
                    gesture; required on mobile where autoplay is blocked
  6. COI SW flag — sets ensureCrossOriginIsolationHeaders to false; COOP/COEP
                   are handled by nginx so Godot's SW shim is redundant and can
                   produce unstable behaviour under Lighthouse audits
"""

import os
import re
import sys
from pathlib import Path

if len(sys.argv) < 2:
    print("Usage: patch_index.py <path/to/index.html>", file=sys.stderr)
    sys.exit(1)

path = Path(sys.argv[1])
html = path.read_text(encoding="utf-8")

THEME_COLOR = os.environ.get("THEME_COLOR", "#00b700")
GAME_NAME   = os.environ.get("GAME_NAME",   "doodleblob")
GAME_URL    = os.environ.get("GAME_URL",    "https://game.fretu.stream").rstrip("/")

# ── 1. Viewport ────────────────────────────────────────────────────────────────
html = html.replace(
    '<meta name="viewport" content="width=device-width, user-scalable=no, initial-scale=1.0">',
    '<meta name="viewport" content="width=device-width, initial-scale=1.0">',
)

# ── 2. Remove Godot manifest reference ─────────────────────────────────────────
html = re.sub(
    r'<link rel="manifest" href="index\.manifest\.json">\s*',
    "",
    html,
)

# ── 3. Head injection ──────────────────────────────────────────────────────────
inject_head = f"""
  <link rel="manifest" href="/manifest.webmanifest">

  <link rel="canonical" href="{GAME_URL}/">

  <meta name="theme-color" content="{THEME_COLOR}">

  <meta name="description"
        content="Play {GAME_NAME} directly in your browser. A game built with Godot.">

  <meta name="author" content="{GAME_URL}">

  <meta property="og:type"        content="website">
  <meta property="og:title"       content="{GAME_NAME}">
  <meta property="og:description" content="Play {GAME_NAME} directly in your browser.">
  <meta property="og:url"         content="{GAME_URL}/">
  <meta property="og:image"       content="{GAME_URL}/icon_512x512.png">

  <meta name="twitter:card"        content="summary_large_image">
  <meta name="twitter:title"       content="{GAME_NAME}">
  <meta name="twitter:description" content="Play {GAME_NAME} directly in your browser.">
  <meta name="twitter:image"       content="{GAME_URL}/icon_512x512.png">
"""

html = html.replace("</head>", inject_head + "\n</head>")

# ── 4. Canvas sizing ───────────────────────────────────────────────────────────
html = html.replace(
    "overflow: hidden;",
    "overflow: hidden;\n        width: 100vw;\n        height: 100vh;",
)

html = html.replace(
    "#canvas {\n        display: block;\n}",
    "#canvas {\n        display: block;\n        width: 100vw;\n        height: 100vh;\n}",
)

# ── 5. Audio unlock ────────────────────────────────────────────────────────────
audio_unlock = """\
<script>
(function () {
  var AudioContext = window.AudioContext || window.webkitAudioContext;
  if (!AudioContext) return;

  var ctx = new AudioContext();

  function resume() {
    if (ctx.state === "suspended") {
      ctx.resume().catch(function () {});
    }
    document.removeEventListener("click",      resume);
    document.removeEventListener("touchstart", resume);
    document.removeEventListener("keydown",    resume);
  }

  document.addEventListener("click",      resume, { passive: true });
  document.addEventListener("touchstart", resume, { passive: true });
  document.addEventListener("keydown",    resume, { passive: true });
}());
</script>
"""

html = html.replace("<noscript>", audio_unlock + "\n<noscript>")

# ── 6. Disable Godot COI SW injection ──────────────────────────────────────────
html = html.replace(
    '"ensureCrossOriginIsolationHeaders":true',
    '"ensureCrossOriginIsolationHeaders":false',
)

path.write_text(html, encoding="utf-8")
print(f"Patched: {path}")
