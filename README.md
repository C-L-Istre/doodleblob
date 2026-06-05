# Godot Web Deploy Template

A self-hosted CI/CD template for building and deploying Godot 4 games as Progressive Web Apps,
with atomic staging/production deployments on a Proxmox LXC container.

---

## Overview

This template wires together three layers:

- A **Proxmox LXC container** running Fedora, Caddy, and the Godot headless binary
- A **self-hosted GitHub Actions runner** on that container
- A **GitHub Actions workflow** that builds, patches, and deploys on every push

Push to `staging` → game live at `https://your-domain.com/staging`  
Push to `main` → game live at `https://your-domain.com/`

The deployment is **atomic**: a symlink swap means no request ever sees a half-deployed build.
The last 10 non-live builds are retained on disk for quick rollback.

---

## Prerequisites

- **Proxmox VE host** with ZFS storage (`local-zfs`) and a Fedora 43 LXC template
  (`local:vztmpl/fedora-43-default_20260115_amd64.tar.xz`)
- **nginx reverse proxy** already running on your network — it handles TLS and the
  cross-origin headers required by Godot's threaded web export
  (see [Nginx Configuration](#nginx-configuration))
- **GitHub repository** (or Gitea — see [Using Gitea](#using-gitea))
- **GitHub Personal Access Token** with `repo` scope — only needed during provisioning to
  register the runner; the token is not stored after setup

---

## Quick Start

### 1. Provision the LXC

Run `godot-deploy.sh` **on your Proxmox host**. The only required argument is the container ID (CTID):

```bash
# Minimum — no runner, just the build environment
bash godot-deploy.sh 200

# With GitHub Actions runner
REPO_URL=https://github.com/your-org/your-game \
GITHUB_PAT=ghp_xxxxxxxxxxxx \
RUNNER_ENABLE=1 \
bash godot-deploy.sh 200
```

The script will destroy any existing container at that ID, create a fresh one, install
Godot and its export templates, configure Caddy, and optionally register the runner.
See [Infrastructure Script Reference](#infrastructure-script-godot-deploysh) for all options.

### 2. Point nginx at the Container

Get the container's IP from the script output (`CT IP: x.x.x.x`), then configure nginx
to proxy requests to it on port 8080. See [Nginx Configuration](#nginx-configuration).

To get a stable IP, pin a MAC address:

```bash
MAC=02:00:de:ad:be:ef RUNNER_ENABLE=1 \
REPO_URL=... GITHUB_PAT=... \
bash godot-deploy.sh 200
```

Then create a static DHCP lease for that MAC on your router.

### 3. Configure Your Repository

Edit `.github/config.json` with your domain and PWA theme color:

```json
{
  "domain": "your-game.example.com",
  "theme_color": "#3b82f6"
}
```

### 4. Add PWA Assets

Replace the placeholder files in `.github/PWA/`:

| File | Dimensions | Purpose |
|---|---|---|
| `icon_144x144.png` | 144×144 | Standard PWA icon |
| `icon_180x180.png` | 180×180 | iOS home screen icon |
| `icon_512x512.png` | 512×512 | Maskable PWA icon (safe-zone art) |
| `desktop.png` | 1280×720 | App store / install prompt screenshot |
| `mobile.png` | 1080×1920 | Mobile install prompt screenshot |
| `coi-serviceworker.js` | — | SharedArrayBuffer polyfill (keep as-is) |

The workflow generates the `manifest.webmanifest` from these assets and the config values —
you never edit the manifest by hand.

### 5. Push to Deploy

```bash
git push origin staging    # → https://your-domain.com/staging
git push origin main       # → https://your-domain.com/
```

---

## Repository Layout

```
your-game/
├── .editorconfig
├── .gitattributes              # LF normalization
├── .gitignore                  # Excludes .godot/, addons/, exports/, export_presets.cfg
│
├── .github/
│   ├── config.json             # domain + theme_color
│   ├── PWA/
│   │   ├── coi-serviceworker.js
│   │   ├── icon_144x144.png
│   │   ├── icon_180x180.png
│   │   ├── icon_512x512.png
│   │   ├── desktop.png         # 1280×720 wide screenshot
│   │   └── mobile.png          # 1080×1920 screenshot
│   └── workflows/
│       └── deploy.yml
│
├── assets/
│   ├── fonts/
│   ├── music/
│   ├── sounds/
│   └── sprites/
│       ├── blocks/
│       ├── characters/
│       ├── enemies/
│       ├── npcs/
│       ├── pickups/
│       └── platforms/
│
├── audio/
│   └── default_bus_layout.tres  # Three buses: Master, Music, SFX
│
├── scenes/
│   ├── characters/
│   ├── enemies/
│   ├── levels/
│   │   └── level_template.tscn  # Starting point for new levels
│   ├── misc/
│   │   ├── kill_zone.tscn
│   │   ├── level_exit.tscn
│   │   └── music.tscn           # Autoloaded AudioStreamPlayer
│   ├── objects/
│   ├── pickups/
│   └── ui/
│       ├── main_menu.tscn
│       ├── pause_menu.tscn
│       ├── settings_panel.tscn
│       └── touch_controls.tscn
│
├── scripts/                     # All GDScript files (flat)
│
├── export_presets.cfg           # Web + Windows + Linux presets
├── project.godot
└── icon.svg
```

> `export_presets.cfg` is excluded from `.gitignore` in this template because the Web
> preset is required by CI. Adjust if your workflow differs.

---

## Server Layout

After provisioning and the first deploy, the server looks like this:

```
/var/www/godot/                              ← WEB root (served by Caddy)
├── production → releases/1748527200-a1b2c3d/  ← atomic symlink (live build)
├── staging    → releases/1748527100-e4f5g6h/  ← atomic symlink (live build)
└── releases/
    ├── 1748527200-a1b2c3d/      ← {unix-timestamp}-{git-sha-7}
    │   ├── index.html
    │   ├── index.js
    │   ├── index.wasm
    │   ├── index.pck
    │   ├── manifest.webmanifest
    │   ├── robots.txt
    │   ├── icon_144x144.png
    │   ├── icon_180x180.png
    │   ├── icon_512x512.png
    │   └── screenshots/
    │       ├── desktop.png
    │       └── mobile.png
    ├── 1748527100-e4f5g6h/      ← previous build (retained)
    └── ...                       ← up to 10 non-live builds retained

/var/lib/godot/                              ← CI_BASE (build scratch space)
└── workspace/                               ← rsync'd project dir, rebuilt each run
```

Before the first deploy, `production` and `staging` point to placeholder directories
containing a stub `index.html`. These are replaced atomically on first push.

---

## Infrastructure Script (`godot-deploy.sh`)

Run this once on your Proxmox host to provision the container. It is **idempotent** —
re-running it destroys the old container and creates a fresh one. Build history inside the
container will be lost unless `WEB` is on a separate mounted volume.

### Variables

All variables can be overridden by environment. Defaults are shown.

**Container**

| Variable | Default | Description |
|---|---|---|
| `GODOT_VERSION` | `4.6.3.stable` | Godot version to install |
| `CTID` | *(required, first arg)* | Proxmox container ID |
| `TEMPLATE` | Fedora 43 path | LXC template on the Proxmox host |
| `BRIDGE` | `vmbr0` | Network bridge |
| `MAC` | *(none)* | Fixed MAC (for static DHCP leases) |
| `CORES` | `8` | vCPU cores |
| `MEMORY` | `16384` | RAM in MB |
| `SWAP` | `1024` | Swap in MB |
| `DISK` | `32` | Root disk in GB (ZFS) |

**Server Paths**

| Variable | Default | Description |
|---|---|---|
| `BUILD_USER` | `godot` | UNIX user that owns builds and the runner |
| `WEB` | `/var/www/godot` | Document root (Caddy serves from here) |
| `CI_BASE` | `/var/lib/godot` | Build workspace root |

**Checksums and URLs**

| Variable | Description |
|---|---|
| `GODOT_BIN_SHA256` | SHA-256 of the Godot Linux binary zip |
| `TEMPLATES_SHA256` | SHA-256 of the export templates archive |
| `GITHUB_BINARY_URL` | Godot binary download URL (auto-derived from version) |
| `GITHUB_TEMPLATES_URL` | Export templates primary URL (GitHub Releases) |
| `SOURCEFORGE_TEMPLATES_URL` | Export templates fallback URL (SourceForge mirror) |
| `MIN_TPZ_BYTES` | `500000000` — minimum valid template archive size |

**GitHub Actions Runner** (only needed if `RUNNER_ENABLE=1`)

| Variable | Default | Description |
|---|---|---|
| `RUNNER_ENABLE` | `0` | Set to `1` to install and register the runner |
| `RUNNER_VERSION` | `2.334.0` | GitHub Actions runner version |
| `RUNNER_SHA256` | *(see script)* | SHA-256 of the runner archive |
| `REPO_URL` | *(required)* | `https://github.com/org/repo` |
| `GITHUB_PAT` | *(required)* | PAT with `repo` scope — used once for token exchange |

### Install Strategy

**Godot binary** — tried in order:

1. GitHub Releases (binary zip, SHA-256 verified)
2. `dnf install godot` fallback — emits a version warning if the repo version doesn't match
   `GODOT_VERSION`

**Export templates** — tried in order:

1. GitHub Releases (primary)
2. SourceForge mirror (fallback)

Both template sources are verified against `TEMPLATES_SHA256` before extraction. The download
is also checked against `MIN_TPZ_BYTES` (500 MB) to catch truncated downloads before
running SHA verification.

### Runner Registration

When `RUNNER_ENABLE=1`, the script:

1. Exchanges `GITHUB_PAT` for a one-time registration token (valid 60 minutes)
2. Downloads and verifies the runner archive
3. Calls `./config.sh --unattended` as `BUILD_USER`
4. Installs and starts the runner as a systemd service
5. Writes a systemd drop-in to put `/usr/local/bin` on the runner's `PATH`
   (so `godot` is found by workflow steps)

The `GITHUB_PAT` is used only during provisioning and is not stored in the container.

### Post-Provisioning Verification

The script checks:

- Caddy is active and returns HTTP 200 at `/` and `/staging/`
- `/staging` returns 308 (redirect to `/staging/`)
- Caddy is **not** setting `Cross-Origin-Opener-Policy` (nginx must set it, not Caddy)
- The `BUILD_USER` exists and `godot --version` runs

---

## CI/CD Pipeline (`deploy.yml`)

### Trigger

Runs on every push to `main` or `staging`. The concurrency group `godot-web-deploy` means
only one run executes at a time — a new push cancels any in-progress run.

> **Note**: the concurrency group is shared across both branches, so simultaneous pushes to
> `main` and `staging` will cancel each other. This is intentional — only the latest push
> to each branch matters in practice.

### Runner Labels

The workflow requires a runner tagged `self-hosted`, `godot`, and `proxmox`. The provisioning
script registers the runner with these labels automatically. You can add additional labels
(e.g. a project name) by modifying the `--labels` argument in the `RUNNER` heredoc.

### Pipeline Steps

#### Step 1 — Load Config

```python
cfg = json.load(open(".github/config.json"))
# exports to $GITHUB_ENV:
#   DOMAIN      = cfg["domain"]
#   THEME_COLOR = cfg["theme_color"]
#   GAME_NAME   = github.event.repository.name
```

`GAME_NAME` is always the repository name, so renaming the repo is the one-stop way to
update the manifest and all SEO tags.

#### Step 2 — Set Deployment Metadata

| Branch | `GAME_URL` | `IS_STAGING` |
|---|---|---|
| `main` | `https://DOMAIN` | `0` |
| `staging` | `https://DOMAIN/staging` | `1` |

#### Step 3 — Prepare Workspace

Rsyncs the checked-out repository to `$CI_BASE/workspace/`, excluding paths that are
either unnecessary for a headless build or regenerated by Godot:

- `.git/`, `.bak` — VCS metadata
- `.godot/`, `.import/` — regenerated by the import step
- `addons/` — excluded from the Web export preset
- `exports/` — local export output directory

#### Step 4 — Import Project

```bash
godot --headless --path $WORKSPACE --import --quit
```

Populates `.godot/` — the shader cache and resource UID index. This step is mandatory
before export; skipping it causes the export to fail or produce an incomplete build.

#### Step 5 — Export Web Build

```bash
godot --headless --path $WORKSPACE --export-release Web $BUILD_DIR/index.html
```

Uses the `Web` preset from `export_presets.cfg`. Outputs `index.html`, `index.js`,
`index.wasm`, and `index.pck` into a new build directory named
`$RELEASES/{unix-timestamp}-{git-sha-7}`.

#### Step 6 — Remove Godot's Manifest

Godot generates `index.manifest.json` as part of its PWA export. This file is deleted
because the CI pipeline generates a standards-compliant `manifest.webmanifest` instead,
with correct icon paths, screenshots, and display settings.

#### Step 7 — Copy CI-Owned PWA Assets

Icons and screenshots from `.github/PWA/` are copied into the build directory. These are
version-controlled assets — they are not generated by Godot and are not affected by
re-exporting the game.

#### Step 8 — Generate Web Manifest

A `manifest.webmanifest` is generated from `GAME_NAME`, `THEME_COLOR`, and `GAME_URL`.
The manifest declares:

- `window-controls-overlay` + `standalone` display modes
- All three icon sizes (144, 180, 512)
- The 512×512 icon marked as `"purpose": "maskable any"` for adaptive icons
- Desktop (1280×720) and mobile (1080×1920) screenshots

#### Step 9 — Generate robots.txt

| Branch | Content |
|---|---|
| `staging` | `Disallow: /` — blocks all crawlers |
| `main` | `Allow: /` — with a `Sitemap:` directive |

Caddy also sets `X-Robots-Tag: noindex, nofollow, noarchive` on all staging responses
as a belt-and-suspenders measure.

#### Step 10 — Patch index.html

A Python script makes the following changes to Godot's exported `index.html`:

| Change | Reason |
|---|---|
| Remove `user-scalable=no` from viewport | Improves accessibility |
| Remove Godot's `index.manifest.json` link | Replaced by CI manifest |
| Inject `<link rel="manifest">` | Points to CI-generated `manifest.webmanifest` |
| Inject canonical URL, theme-color | SEO |
| Inject Open Graph + Twitter Card tags | Social sharing previews |
| Add `width/height: 100vw/vh` to canvas | Full-viewport layout |
| Inject audio context unlock snippet | Browsers suspend AudioContext until user interaction; this resumes it on first click/touch/keydown |
| Set `ensureCrossOriginIsolationHeaders: false` | Godot's built-in COOP/COEP injection is disabled because nginx handles these headers — Caddy must not duplicate them |

#### Step 11 — Validate Output

Checks that all required files exist in the build directory before deploying. Fails the
build if any are missing, preventing a broken deploy.

Required files: `index.html`, `index.js`, `index.wasm`, `index.pck`,
`manifest.webmanifest`, `icon_144x144.png`, `icon_180x180.png`, `icon_512x512.png`,
`screenshots/desktop.png`, `screenshots/mobile.png`.

#### Step 12 — Atomic Deploy

```bash
ln -sfn "$BUILD_DIR" "${TARGET}.tmp"
mv -Tf "${TARGET}.tmp" "$TARGET"
```

`mv -T` is atomic on Linux. No request is ever served from a partial or mixed-version
build — the old build remains live until the new one is fully in place.

#### Step 13 — Validate Symlink

Reads the deployed symlink and confirms it points to the expected build directory.
Fails the run if the symlink target doesn't match.

#### Step 14 — Cleanup Old Releases

Keeps the 10 most recent build directories that are **not** currently pointed to by either
the production or staging symlink. Currently-live builds are always preserved regardless
of age.

---

## Nginx Configuration

Caddy runs inside the LXC on port 8080 and is intentionally not exposed to the internet.
Your nginx instance (external to the container) must:

1. **Terminate TLS**
2. **Proxy to the container**
3. **Add COOP/COEP headers**

Minimal nginx virtual host:

```nginx
server {
    listen 443 ssl;
    server_name your-game.example.com;

    # TLS config omitted — use Certbot or your CA of choice

    location / {
        proxy_pass http://<container-ip>:8080;
        proxy_set_header Host $host;

        # Required for Godot threaded web export (SharedArrayBuffer)
        add_header Cross-Origin-Opener-Policy  "same-origin"   always;
        add_header Cross-Origin-Embedder-Policy "require-corp"  always;
    }
}
```

> **Critical**: these two headers must be set **only by nginx**, not by Caddy. If both
> servers set them, browsers receive duplicate headers and treat Cross-Origin Isolation
> as misconfigured, causing SharedArrayBuffer to be unavailable and the game to fail.

---

## Caddy Configuration

Caddy is configured by the provisioning script and serves on port 8080. The Caddyfile
is written to `/etc/caddy/Caddyfile` inside the container.

What Caddy handles:

- Production (`/`) served from `$WEB/production` (symlink target)
- Staging (`/staging/*`) served from `$WEB/staging` (symlink target)
- `GET /staging` → `308 /staging/` redirect
- SPA route fallback: any path that isn't a file or a known asset extension rewrites to
  `index.html` (supports client-side routing)
- `Cache-Control: no-cache` on `index.html` (always revalidated)
- `Cache-Control: no-store` on the service worker script
- `X-Robots-Tag: noindex, nofollow, noarchive` on all staging responses

What nginx handles (not Caddy):

- TLS termination
- `Cross-Origin-Opener-Policy` and `Cross-Origin-Embedder-Policy` headers

---

## Export Presets (`export_presets.cfg`)

The `Web` preset is the one used by CI. Key settings and their reasons:

| Setting | Value | Why |
|---|---|---|
| `variant/thread_support` | `true` | Required for SharedArrayBuffer and Godot's thread pool |
| `html/export_icon` | `false` | CI supplies its own versioned icons |
| `html/canvas_resize_policy` | `2` | Stretch canvas to fill viewport |
| `progressive_web_app/enabled` | `false` | CI generates the manifest — Godot's PWA generation is disabled to avoid conflicts |
| `progressive_web_app/ensure_cross_origin_isolation_headers` | `false` | nginx handles COOP/COEP |
| `exclude_filter` | `addons/godot-git*` | Excludes the git plugin from the exported build |

The `Windows Desktop` and `Linux` presets are for local development builds only.
Update their `export_path` values for your machine before using them locally; these
paths are not used by CI.

---

## Included GDScript Modules

These scripts are included as a functional starting point. They are designed to be
adapted or removed — none of them contain hardcoded game content.

### Autoloads

These are registered in `project.godot` under `[autoload]` and are globally accessible
by name in any script.

**`PlatformDetection`** (`scripts/platform_detection.gd`)

Detects the current runtime platform. Used by UI scripts to conditionally show or hide
controls that only make sense on desktop (exit button, resolution/fullscreen settings).

```gdscript
PlatformDetection.get_platform()   # → PlatformType enum (DESKTOP, WEB, MOBILE)
PlatformDetection.can_quit()       # → bool; false on web and mobile
PlatformDetection.exit_game()      # platform-aware quit — no-op on web/mobile
```

**`ScoreManager`** (`scripts/score_manager.gd`)

Tracks an integer current score and high score. Persists high score between sessions
using `user://save.cfg`.

```gdscript
ScoreManager.add_point()       # increment current score by 1
ScoreManager.finish_level()    # update high score if current score exceeds it
ScoreManager.reset_score()     # reset current score to 0
ScoreManager.current_score     # int (read)
ScoreManager.high_score        # int (read)
```

To remove the score system, delete `score_manager.gd`, remove it from `[autoload]` in
`project.godot`, and remove `ScoreManager.add_point()` calls from pickup scripts.

**`HealthManager`** (`scripts/health_manager.gd`)

Tracks lives and drives game-over transitions. Emits `lives_changed` (HUD),
`life_lost` (player reloads scene), and loads `game_over.tscn` directly when
lives reach zero. Call `reset_game()` at the start of a new game.

```gdscript
HealthManager.lose_life()           # called from player.die()
HealthManager.gain_life(amount)     # power-up, milestone reward
HealthManager.reset_game()          # reset to STARTING_LIVES
HealthManager.lives                 # int (read)
```

**`Music`** (`scenes/misc/music.tscn`)

An `AudioStreamPlayer2D` scene configured as an autoload. Because it persists across
scene changes, background music continues uninterrupted between levels. Assign your
background track to the stream property and set the bus to `Music`.

### UI Scripts

**`scripts/settings_panel.gd`**

A `Panel` node that manages audio and display settings. Audio settings (volume + mute
for Main, Music, and SFX buses) work on all platforms. Display settings (resolution,
fullscreen, vsync) are shown only on desktop and hidden on web and mobile.

Settings persist to `user://settings.cfg` immediately on change — no save button required.

```
Audio buses expected: index 0 = Master, 1 = Music, 2 = SFX
(matches the included audio/default_bus_layout.tres)
```

**`scripts/main_menu.gd`**

Manages the main menu. Handles panel visibility switching (level select, high score
display, help, settings). Level paths are stored in a `level_paths` array — add entries
to expose more levels in the level select list.

**`scripts/pause_menu.gd`**

In-game pause overlay. Handles resume, settings panel, return to main menu, and exit.
Sets `process_mode = PROCESS_MODE_ALWAYS` so it receives input while the tree is paused.

**`scripts/control_root.gd`**

Root script for in-game scenes. Holds a reference to the pause menu `CanvasLayer` and
forwards the `pause` input action to it. Attach to the root `Control` node of each
level scene.

### Gameplay Scripts

These are minimal, ready-to-extend implementations:

**`scripts/player.gd`** — `CharacterBody2D` with gravity, WASD/arrow/gamepad movement,
animated sprite flipping, and a `die()` method that reloads the current scene. The
player is registered in the `player` global group.

**`scripts/enemy.gd`** — Patrol enemy using two `RayCast2D` nodes to detect ledges and
walls, reversing direction on contact. Calls `die()` on any body that enters its
`Area2D`.

**`scripts/kill_zone.gd`** — `Area2D` that calls `die()` on any body that enters it.
Use for pits, spikes, and other instant-death hazards.

**`scripts/level_exit.gd`** — `Area2D` that calls `change_scene_to_file()` when a body
in the `player` group enters. Set `next_level_path` in the inspector.

---

## Customization Guide

### Change the Godot Version

1. Set `GODOT_VERSION` when running `godot-deploy.sh`
2. Update `GODOT_BIN_SHA256` (SHA-256 of the new binary zip)
3. Update `TEMPLATES_SHA256` (SHA-256 of the new export templates archive)
4. Update the `Web` export preset in `export_presets.cfg` if the export format changed

```bash
GODOT_VERSION=4.7.0.stable \
GODOT_BIN_SHA256=<new-hash> \
TEMPLATES_SHA256=<new-hash> \
bash godot-deploy.sh 200
```

Get hashes from the Godot release page: `sha256sum Godot_v4.7.0-stable_linux.x86_64.zip`

### Change the Domain

Edit `.github/config.json`:

```json
{
  "domain": "mygame.example.com",
  "theme_color": "#ff6b35"
}
```

The canonical URL, Open Graph tags, sitemap reference, and manifest `start_url` and
`scope` are all derived from `domain` at build time.

### Add Levels

In `main_menu.gd`, append to `level_paths`:

```gdscript
var level_paths: Array[String] = [
    "res://scenes/levels/level_1.tscn",
    "res://scenes/levels/level_2.tscn",
    "res://scenes/levels/level_3.tscn",
]
```

The level select `ItemList` in the main menu scene will populate automatically for any
number of entries. Start from `scenes/levels/level_template.tscn` for new levels.

### Add More Score Types

`ScoreManager` currently tracks a single integer score. To track multiple values (coins,
time, stars), extend the autoload:

```gdscript
var coin_count: int = 0
var completion_time: float = 0.0

func add_coin() -> void:
    coin_count += 1
    add_point()   # still increments the base score
```

### Change Retention Count

Edit the `KEEP` variable in the `Cleanup old releases` step in `deploy.yml`:

```yaml
- name: Cleanup old releases
  shell: bash
  run: |
    KEEP=10   # change to desired number
    ...
```

### Using Gitea

1. Replace `actions/checkout@v4` with the Gitea-hosted checkout action
2. Replace the runner registration block — Gitea uses a different token endpoint
   (`/api/v1/repos/{owner}/{repo}/actions/runners/registration-token`) and registration
   flags
3. `GAME_NAME` currently uses `github.event.repository.name` — replace with the Gitea
   equivalent or hardcode it in `config.json`

---

## Security Notes

- The container runs **unprivileged** (`--unprivileged 1`) with nesting enabled for
  Caddy's socket management.
- `GITHUB_PAT` is used only during provisioning to exchange for a registration token.
  It is printed to no logs and is not written to disk in the container.
- The runner registration token expires 60 minutes after issuance.
- Caddy binds only on port 8080 — expose it only to your nginx proxy, not directly to
  the internet. There is no authentication on the Caddy listener.
- The `$WEB/releases/` directory grows over time. The 10-build retention policy limits
  growth, but on high-frequency projects, monitor disk usage: `pct exec <CTID> -- df -h /`.

---

## Troubleshooting

### Text or sprites are blurry at non-native resolutions

Enable integer scaling in Project Settings → Display → Window → Stretch → **Scale Mode: `integer`**.

Integer scaling only scales the viewport to exact whole multiples (1×, 2×, 3×…) so every
pixel and glyph lands on an exact boundary. Fractional scaling introduces sub-pixel offsets
that blur text regardless of stretch mode or renderer.

On web, the `Mode` setting (`canvas_items` vs `viewport`) has no visible effect on
sharpness — the browser controls the final canvas scaling step, so both modes look
identical. Integer scaling is the only setting that matters for clarity.

**Trade-off:** at resolutions that aren't an exact multiple of the base viewport (640×360),
the engine falls back to the next lower whole multiple and fills the gap with black bars.
At 1920×1080 the scale is an exact 3× (no bars). At 1366×768 it would be 2× with bars.
This is expected behaviour for pixel-perfect rendering.

Currently using viewport, expand, fractional with good results on web.

### Game is blank or audio doesn't work after load

Verify nginx is sending `Cross-Origin-Opener-Policy: same-origin` and
`Cross-Origin-Embedder-Policy: require-corp`. Open DevTools → Network → click on
`index.html` → Response Headers. Both headers must be present **exactly once**.

If either header appears twice, Caddy is also setting it — re-read the COOP/COEP note in
[Caddy Configuration](#caddy-configuration) and remove the headers from the Caddyfile.

### Caddy returns 404 for /staging/

Check that the staging symlink exists and points somewhere valid:

```bash
pct exec <CTID> -- readlink -f /var/www/godot/staging
```

If it points to the initial placeholder (`…/releases/staging/initial`) and that directory
is missing (possible after a cleanup pass), re-run `godot-deploy.sh` to recreate it, or
manually push a build to the `staging` branch.

### Export fails — "No export template found"

Templates are installed to `/home/godot/.local/share/godot/export_templates/$GODOT_VERSION/`.
The export step runs with `HOME=/home/godot`. Verify:

```bash
pct exec <CTID> -- ls /home/godot/.local/share/godot/export_templates/
```

If the directory is empty or missing, re-run `godot-deploy.sh` (or just the bootstrap
portion) with the correct `GODOT_VERSION` and updated checksums.

### Runner not picking up jobs

```bash
pct exec <CTID> -- systemctl status 'actions.runner.*.service'
```

If the unit is stopped, check whether the Godot binary is on the runner's PATH:

```bash
pct exec <CTID> -- sudo -u godot bash -c 'echo $PATH; which godot'
```

The provisioning script writes `/etc/systemd/system/actions.runner.*.service.d/path.conf`
to inject `/usr/local/bin` into the unit's `PATH`. If that file is missing, recreate it
and reload systemd.

### Import step takes very long or hangs

The first import after a clean workspace can take several minutes for large projects
(shader compilation). Subsequent runs are fast because the workspace is not wiped between
builds — only modified files are rsynced. If the import hangs indefinitely, check
`GODOT_SILENCE_ROOT_WARNING=1` is set (missing it causes Godot to block waiting for
stdin in some configurations).

### Concurrent push cancels in-progress deploy

This is intentional — see the `concurrency` block in `deploy.yml`. If you need
independent staging and production pipelines, split `concurrency.group` to
`godot-web-deploy-${{ github.ref_name }}`.

### Audio doesn't play on first load (no error in console)

The audio unlock snippet in `index.html` should handle this by resuming the `AudioContext`
on the first click, touch, or keydown. If it still doesn't work, check that the
`coi-serviceworker.js` in `.github/PWA/` is being served (it enables SharedArrayBuffer
which some browsers require for Godot's audio pipeline).
