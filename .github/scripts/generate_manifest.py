#!/usr/bin/env python3
"""
Generate manifest.webmanifest for the Godot web build.

Reads configuration from environment variables set in the workflow:
  BUILD_DIR    — output directory for the current build
  GAME_NAME    — display name of the game
  THEME_COLOR  — hex colour used for background_color and theme_color
  GAME_URL     — canonical URL (used for screenshot labels)

Lighthouse-relevant decisions:
  id           — explicit app identity; avoids the "id not specified" warning
  purpose      — 512px icon gets "maskable any" for adaptive icon support on
                 Android and the Lighthouse installability check
  screenshots  — desktop (form_factor: wide) and mobile entries enable the
                 richer install UI prompt on both platforms
  display_override — window-controls-overlay for desktop PWA title bar;
                     standalone is the universal fallback
"""

import json
import os
import sys
from pathlib import Path

BUILD_DIR   = os.environ.get("BUILD_DIR")
GAME_NAME   = os.environ.get("GAME_NAME",   "doodleblob")
THEME_COLOR = os.environ.get("THEME_COLOR", "#00b700")
GAME_URL    = os.environ.get("GAME_URL",    "https://game.fretu.stream")

if not BUILD_DIR:
    print("ERROR: BUILD_DIR environment variable is not set", file=sys.stderr)
    sys.exit(1)

manifest = {
    "id": "/index.html",
    "name": GAME_NAME,
    "short_name": GAME_NAME,
    "description": f"{GAME_NAME} is a browser-based game built with Godot.",
    "start_url": "/index.html",
    "scope": "/",
    "display": "standalone",
    "display_override": ["window-controls-overlay", "standalone"],
    "orientation": "any",
    "background_color": THEME_COLOR,
    "theme_color": THEME_COLOR,
    "icons": [
        {
            "src": "/icon_144x144.png",
            "sizes": "144x144",
            "type": "image/png",
            "purpose": "any",
        },
        {
            "src": "/icon_180x180.png",
            "sizes": "180x180",
            "type": "image/png",
            "purpose": "any",
        },
        {
            "src": "/icon_512x512.png",
            "sizes": "512x512",
            "type": "image/png",
            # maskable: content sits within the central 80% safe zone so it
            # renders correctly when cropped to a circle/squircle on Android.
            # "any" allows the browser to use it as a regular icon too.
            "purpose": "maskable any",
        },
    ],
    "screenshots": [
        {
            "src": "/screenshots/desktop.png",
            "sizes": "1280x720",
            "type": "image/png",
            "form_factor": "wide",
            "label": f"{GAME_NAME} — desktop",
        },
        {
            "src": "/screenshots/mobile.png",
            "sizes": "1080x1920",
            "type": "image/png",
            "label": f"{GAME_NAME} — mobile",
        },
    ],
}

out = Path(BUILD_DIR) / "manifest.webmanifest"
out.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n")
print(f"Manifest written: {out}")
