**Controls**

| Action | Keyboard | Gamepad |
|---|---|---|
| Move | A / D or Arrow keys | Left stick / D-pad |
| Jump | Space / W / Up | A / D-pad up |
| Crouch | S / Down | B / D-pad down |
| Pause | Escape | Start / Back / Home / Guide / Etc... |

Touch controls are available in the web and mobile builds (on-screen buttons rendered by `scenes/ui/touch_controls.tscn`).

**Autoloads (global singletons)**

- `PlatformDetection` — detects Desktop / Web / Mobile at runtime; gates platform-specific behaviour (quit button, fullscreen/resolution controls)
- `ScoreManager` — tracks current score and high score; persists high score to `user://save.cfg`
- `Music` — background music node, always-on across scene changes

**Settings** (persisted to `user://settings.cfg`)

- Audio: independent volume sliders and mute toggles for Main, Music, and SFX buses
- Display (desktop only): resolution (720p – 1440p), fullscreen, vsync

---

## Repository layout

```
.github/
  PWA/              PWA assets owned by CI (icons, screenshots, coi-serviceworker.js)
  workflows/
    deploy.yml      GitHub Actions build + deploy pipeline
assets/
  fonts/            PixelOperator8 (regular + bold)
  music/            Background track
  sounds/           SFX (coin pickup)
  sprites/          Source Aseprite files + exported PNGs, organised by category
audio/
  default_bus_layout.tres
scenes/             scenes/
  characters/       player.tscn
  enemies/          bear.tscn
  npcs/             triangela.tscn
  levels/           level_1–3.tscn, level_template.tscn
  misc/             kill_zone.tscn, level_exit.tscn, music.tscn
  objects/          platform.tscn, stoneblock.tscn
  pickups/          coin.tscn
  ui/               main_menu.tscn, pause_menu.tscn, settings_panel.tscn, touch_controls.tscn
scripts/            GDScript source files (one per scene)
export_presets.cfg  Godot web export preset ("Web")
project.godot       Project config — Godot 4.6, GL Compatibility renderer, 1280×720
godot-deploy.sh     Proxmox LXC provisioning script (see Infrastructure below)
```

---

## CI/CD pipeline

The workflow in `.github/workflows/deploy.yml` runs on every push to `main` or `staging` on a self-hosted runner inside the Proxmox container. Concurrent runs cancel each other (one deploy at a time).

**Steps**

1. **Checkout** — standard `actions/checkout@v4`
2. **Prepare workspace** — rsyncs source into `/var/lib/godot/workspace`, excluding `.godot/`, `.import/`, and `addons/`
3. **Import project** — runs `godot --headless --import --quit` to generate the `.godot/` cache
4. **Export web build** — runs `godot --headless --export-release Web`; output lands in `/var/www/godot/releases/<timestamp>-<sha7>/`
5. **Remove Godot-generated manifest** — strips `index.manifest.json` (replaced by the CI-owned manifest below)
6. **Copy CI-owned PWA assets** — icons (144, 180, 512 px) and screenshots (desktop + mobile) from `.github/PWA/`
7. **Add Lighthouse bootstrap layer** — injects `bootstrap.js` into `<head>` if present in `.github/PWA/` (optional performance layer)
8. **Generate CI-owned manifest** — writes `manifest.webmanifest` with correct `id`, `start_url`, icons, screenshots, theme colour (`#00b700`), and `display_override: ["window-controls-overlay", "standalone"]`
9. **Generate `robots.txt`**
10. **Patch `index.html`** — Python script that:
    - Fixes the viewport meta tag (removes `user-scalable=no`)
    - Swaps the Godot manifest link for the CI manifest
    - Injects canonical URL, Open Graph, Twitter Card, and theme-color meta tags
    - Forces `100vw / 100vh` on `<body>` and `#canvas`
    - Adds an audio-context unlock handler (required for autoplay policy on mobile/web)
    - Sets `ensureCrossOriginIsolationHeaders: false` (headers are handled by nginx, not by Godot's engine check)
11. **Validate output** — asserts all required files exist before deploying
12. **Deploy** — atomically swaps the live symlink (`ln -sfn`) to the new release directory; `main` → `/var/www/godot/production`, `staging` → `/var/www/godot/staging`
13. **Cleanup** — keeps the 10 most recent release directories; deletes the rest

---

## Infrastructure

`godot-deploy.sh` provisions a fresh Proxmox LXC container from scratch. Run it once per server. It is idempotent: if the container ID already exists it is destroyed and recreated.

### Prerequisites

- Proxmox host with the Fedora 43 LXC template (`fedora-43-default_20260115_amd64.tar.xz`) in local storage
- A GitHub PAT with `repo` scope (only needed if `RUNNER_ENABLE=1`)

### What it provisions

- **Fedora 43 LXC container** (unprivileged, nesting enabled) with configurable cores, RAM, swap, and disk
- **Base packages**: git, rsync, curl, unzip, caddy, fontconfig, and the Godot 4 runtime libraries
- **Godot binary** — downloaded from GitHub releases and SHA-256 verified; falls back to `dnf install godot` if GitHub is unreachable
- **Godot export templates** — downloaded from GitHub (SourceForge mirror as fallback), size- and SHA-256-verified, extracted to `/home/godot/.local/share/godot/export_templates/<version>/`
- **`godot` system user** — owns `/var/lib/godot/` (workspace, builds, releases, runner)
- **Directory structure**:
  ```
  /var/www/godot/
    releases/
      production/initial/    seed placeholder (never overwritten)
      staging/initial/       seed placeholder (never overwritten)
    production -> releases/production/initial   (symlink, updated on deploy)
    staging    -> releases/staging/initial       (symlink, updated on deploy)
  ```
- **Caddy** — origin file server on port 8080; handles production at `/` and staging at `/staging/`, SPA route fallback, and per-route cache headers. Caddy does **not** set COOP/COEP headers — those are set by nginx upstream to avoid duplicate headers that break Cross-Origin Isolation.
- **GitHub Actions runner** (optional, `RUNNER_ENABLE=1`) — downloaded, SHA-256 verified, configured against your repo, installed as a systemd service, and given a PATH override so `/usr/local/bin/godot` is visible during workflow runs

### Quick deploy

```bash
# With runner registration (most common)
sudo RUNNER_ENABLE=1 \
     REPO_URL="https://github.com/<user>/<repo>" \
     GITHUB_PAT="<pat>" \
     bash godot-deploy.sh <CTID>

# Without a runner (file server only)
sudo bash godot-deploy.sh <CTID>

# Optional overrides
sudo RUNNER_ENABLE=1 \
     REPO_URL="https://github.com/<user>/<repo>" \
     GITHUB_PAT="<pat>" \
     MAC="xx:xx:xx:xx:xx:xx" \
     CORES=4 \
     MEMORY=8192 \
     DISK=20 \
     bash godot-deploy.sh <CTID>
```

Provisioning takes 5–15 minutes depending on download speed. The script prints the container IP and HTTP health check results when complete.

**All configurable variables**

| Variable | Default | Description |
|---|---|---|
| `GODOT_VERSION` | `4.6.3.stable` | Godot version to install |
| `CTID` | *(required, positional)* | Proxmox container ID |
| `TEMPLATE` | Fedora 43 template path | LXC template |
| `BRIDGE` | `vmbr0` | Network bridge |
| `MAC` | *(unset)* | Fixed MAC for DHCP reservation |
| `CORES` | `8` | vCPU count |
| `MEMORY` | `16384` | RAM in MB |
| `SWAP` | `1024` | Swap in MB |
| `DISK` | `32` | Root disk in GB |
| `RUNNER_ENABLE` | `0` | Set to `1` to install the GitHub runner |
| `REPO_URL` | *(unset)* | `https://github.com/<user>/<repo>` |
| `GITHUB_PAT` | *(unset)* | PAT with `repo` scope |
| `RUNNER_VERSION` | `2.334.0` | Actions runner version |

### Re-registering the runner

Registration tokens expire after 60 minutes. If the token expires before provisioning finishes, re-register without reprovisioning:

```bash
pct exec <CTID> -- env \
  RUNNER_TOKEN="<fresh-token>" \
  REPO_URL="https://github.com/<user>/<repo>" \
  CTID="<CTID>" \
  bash -s <<'EOF'
RUNNER_DIR="/home/godot/runner"
runuser -u godot -- bash -lc "
  cd '$RUNNER_DIR'
  ./config.sh --unattended \
    --url '$REPO_URL' \
    --token '$RUNNER_TOKEN' \
    --name 'gd-$CTID' \
    --labels 'proxmox,gd-$CTID,godot' \
    --work _work \
    --runasservice \
    --replace
"
cd "$RUNNER_DIR"
./svc.sh install godot
./svc.sh start
EOF
```

### Nginx reverse proxy requirements

Caddy runs on port 8080 and expects nginx (or another proxy) in front of it for TLS and the headers required for Godot's multithreaded web export:

```nginx
add_header Cross-Origin-Opener-Policy   "same-origin" always;
add_header Cross-Origin-Embedder-Policy "require-corp" always;
```

Do not set these headers in the Caddyfile. If both Caddy and nginx set them, the browser receives duplicate headers and Cross-Origin Isolation fails.

---

## Local development

Open the project in the Godot 4.6 editor and run from there. No additional setup required.

To test a web export locally you need a server that sets the COOP/COEP headers above. The simplest option:

```bash
# Python + a local proxy, or use the Godot editor's built-in "Export → Run in Browser" which sets the headers automatically
```

---

## Notes

- The `coi-serviceworker.js` in `.github/PWA/` is a fallback shim that injects COOP/COEP via a service worker for environments where the reverse proxy cannot set them (e.g. GitHub Pages). It is copied into every build directory and loaded by Godot's export template automatically.
- The web manifest `id` field is set to `/index.html` so reinstalls of the PWA resolve to the same app identity regardless of URL variations.
- The `audio_unlock` script injected by the deploy pipeline creates and resumes a Web Audio `AudioContext` on the first user gesture, working around autoplay restrictions in Chrome, Firefox, and Safari on mobile.
