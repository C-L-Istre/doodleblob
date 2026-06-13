#!/usr/bin/env bash
set -euo pipefail

log() { echo "[provision] $*"; }

# =========================
# INPUTS 
# =========================

GODOT_VERSION="${GODOT_VERSION:-4.6.3.stable}"

# Derived version strings — computed once here and passed into the bootstrap
# environment so the heredoc never needs to re-derive them.
GV_TAG="${GODOT_VERSION//.stable/-stable}"   # e.g. 4.6.3-stable
GV_NUM="${GODOT_VERSION%.stable}"            # e.g. 4.6.3

# ── Container ──────────────────────────────────────────────────────────────────
TEMPLATE="${TEMPLATE:-local:vztmpl/fedora-43-default_20260115_amd64.tar.xz}"
CTID="${1:?CTID required}"
HOSTNAME="godot-$GV_NUM"
BRIDGE="${BRIDGE:-vmbr0}"
MAC="${MAC:-}"
CORES="${CORES:-8}"
MEMORY="${MEMORY:-16384}"
SWAP="${SWAP:-1024}"
DISK="${DISK:-32}"

# ── Server paths ────────────────────────────────────────────────────────────────
BUILD_USER="${BUILD_USER:-godot}"            # UNIX user that owns builds and the runner
WEB="${WEB:-/var/www/godot}"                 # document root; Caddy serves from here
CI_BASE="${CI_BASE:-/var/lib/godot}"         # build workspace root

# ── Godot checksums ─────────────────────────────────────────────────────────────
# Update both hashes when upgrading GODOT_VERSION.
# Obtain with: sha256sum Godot_vX.Y.Z-stable_linux.x86_64.zip
#              sha256sum Godot_vX.Y.Z-stable_export_templates.tpz
GODOT_BIN_SHA256="${GODOT_BIN_SHA256:-d0bc2113065e481c9c2c2b2c37daa4e8be3fe9e27f0ab9ab0b6096e9a37907f3}"
TEMPLATES_SHA256="${TEMPLATES_SHA256:-3fbe2c0e2dec9d537ab9ec97bcf8da91dcf23357fc51f67092dd068d839290a8}"
MIN_TPZ_BYTES=500000000

# ── Download URLs ───────────────────────────────────────────────────────────────
# Override these if you mirror releases internally.
GITHUB_BINARY_URL="${GITHUB_BINARY_URL:-https://github.com/godotengine/godot/releases/download/${GV_TAG}/Godot_v${GV_TAG}_linux.x86_64.zip}"
GITHUB_TEMPLATES_URL="${GITHUB_TEMPLATES_URL:-https://github.com/godotengine/godot/releases/download/${GV_TAG}/Godot_v${GV_TAG}_export_templates.tpz}"
SOURCEFORGE_TEMPLATES_URL="${SOURCEFORGE_TEMPLATES_URL:-https://cytranet.dl.sourceforge.net/project/godot-engine.mirror/${GV_NUM}-stable/Godot_v${GV_TAG}_export_templates.tpz}"

# ── GitHub Actions runner (optional) ────────────────────────────────────────────
# Set RUNNER_ENABLE=1 and provide REPO_URL + GITHUB_PAT to install and register
# a self-hosted runner. GITHUB_PAT is used only during provisioning (token exchange)
# and is not stored in the container.
REPO_URL="${REPO_URL:-}"
GITHUB_PAT="${GITHUB_PAT:-}"
RUNNER_ENABLE="${RUNNER_ENABLE:-0}"
RUNNER_VERSION="${RUNNER_VERSION:-2.334.0}"
RUNNER_SHA256="${RUNNER_SHA256:-048024cd2c848eb6f14d5646d56c13a4def2ae7ee3ad12122bee960c56f3d271}"

# =========================
# DESTROY IF EXISTS
# =========================

if pct status "$CTID" &>/dev/null; then
  log "Destroying existing CT $CTID"
  pct stop "$CTID" || true
  pct destroy "$CTID" --force
fi

# =========================
# CREATE CT
# =========================

log "Creating CT $CTID (hostname: $HOSTNAME)"

NETCFG="name=eth0,bridge=$BRIDGE,ip=dhcp"
[[ -n "$MAC" ]] && NETCFG="$NETCFG,hwaddr=$MAC"

pct create "$CTID" "$TEMPLATE" \
  --hostname  "$HOSTNAME" \
  --cores     "$CORES" \
  --memory    "$MEMORY" \
  --swap      "$SWAP" \
  --rootfs    "local-zfs:$DISK" \
  --net0      "$NETCFG" \
  --unprivileged 1 \
  --features  nesting=1 \
  --onboot    1

pct start "$CTID"

# =========================
# WAIT FOR IP
# =========================

log "Waiting for network..."
sleep 2

IP=""
for i in $(seq 1 60); do
  IP=$(pct exec "$CTID" -- hostname -I 2>/dev/null | awk '{print $1}' || true)
  [[ -n "$IP" ]] && break
  sleep 1
done

[[ -z "$IP" ]] && { echo "[ERROR] No IP assigned after 60 s"; exit 1; }
log "CT IP: $IP"

# =========================
# BOOTSTRAP (INLINE)
# =========================

log "Running bootstrap"

pct exec "$CTID" -- env \
  BUILD_USER="$BUILD_USER" \
  WEB="$WEB" \
  CI_BASE="$CI_BASE" \
  GODOT_VERSION="$GODOT_VERSION" \
  GV_TAG="$GV_TAG" \
  GV_NUM="$GV_NUM" \
  GODOT_BIN_SHA256="$GODOT_BIN_SHA256" \
  GITHUB_BINARY_URL="$GITHUB_BINARY_URL" \
  GITHUB_TEMPLATES_URL="$GITHUB_TEMPLATES_URL" \
  SOURCEFORGE_TEMPLATES_URL="$SOURCEFORGE_TEMPLATES_URL" \
  TEMPLATES_SHA256="$TEMPLATES_SHA256" \
  MIN_TPZ_BYTES="$MIN_TPZ_BYTES" \
  bash -s <<'BOOTSTRAP'
set -euo pipefail

log() { echo "[bootstrap] $*"; }

[[ $EUID -ne 0 ]] && { echo "Run as root"; exit 1; }

# ── BASE PACKAGES ──────────────────────────────────────────────────────────────

log "Installing base packages"
dnf install -y \
  git rsync curl unzip tar gzip ca-certificates sudo caddy \
  fontconfig libGL libXi libXrandr libXinerama libXcursor libXext \
  libicu

# ── GODOT BINARY ──────────────────────────────────────────────────────────────

install_godot_from_github() {
  log "Downloading Godot binary from GitHub: $GITHUB_BINARY_URL"
  local tmp_zip
  tmp_zip="$(mktemp /tmp/godot.XXXXXX.zip)"

  if ! curl -fL --retry 3 --retry-delay 2 "$GITHUB_BINARY_URL" -o "$tmp_zip"; then
    log "GitHub binary download failed"
    rm -f "$tmp_zip"
    return 1
  fi

  log "Verifying Godot binary SHA-256"
  local actual
  actual="$(sha256sum "$tmp_zip" | awk '{print $1}')"
  if [[ "$actual" != "$GODOT_BIN_SHA256" ]]; then
    log "ERROR: binary checksum mismatch (got $actual, expected $GODOT_BIN_SHA256)"
    rm -f "$tmp_zip"
    return 1
  fi

  log "Extracting Godot binary"
  local tmp_dir
  tmp_dir="$(mktemp -d /tmp/godot.XXXXXX)"
  unzip -q "$tmp_zip" -d "$tmp_dir"
  rm -f "$tmp_zip"

  local bin
  bin="$(find "$tmp_dir" -maxdepth 1 -name 'Godot_*linux*' | head -1)"
  [[ -z "$bin" ]] && { log "Binary not found in archive"; rm -rf "$tmp_dir"; return 1; }

  install -m 0755 "$bin" /usr/local/bin/godot
  rm -rf "$tmp_dir"
  log "Godot binary installed to /usr/local/bin/godot"
}

install_godot_from_dnf() {
  log "Falling back to dnf install godot"
  dnf install -y godot

  local installed_ver
  installed_ver="$(godot --headless --version 2>/dev/null | head -1 || true)"
  if [[ "$installed_ver" != *"${GV_NUM}"* ]]; then
    log "WARNING: dnf-installed Godot version ('$installed_ver') does not match GODOT_VERSION ($GODOT_VERSION)"
    log "Continuing — verify export template compatibility manually."
  else
    log "dnf Godot version confirmed: $installed_ver"
  fi
}

log "Installing Godot $GODOT_VERSION"
if ! install_godot_from_github; then
  log "GitHub binary install failed; falling back to dnf"
  install_godot_from_dnf
fi

# ── BUILD USER ────────────────────────────────────────────────────────────────

if ! id "$BUILD_USER" &>/dev/null; then
  log "Creating user $BUILD_USER"
  useradd -m -s /bin/bash "$BUILD_USER"
fi

# ── DIRECTORY STRUCTURE ───────────────────────────────────────────────────────

log "Creating directory structure"

mkdir -p "$CI_BASE"/{workspace,builds,releases,runner}
mkdir -p "$WEB"/releases/{production,staging}/initial

# Seed placeholder pages so Caddy serves a valid response before the first deploy.
# Production and staging use separate seed directories so they never share a target.
cat > "$WEB/releases/production/initial/index.html" <<'EOF'
<!doctype html><html><body><h1>Production not yet deployed.</h1></body></html>
EOF

cat > "$WEB/releases/staging/initial/index.html" <<'EOF'
<!doctype html><html><body><h1>Staging not yet deployed.</h1></body></html>
EOF

# Atomic-swap-safe symlinks: the deploy workflow replaces these with mv -Tf.
ln -sfn "$WEB/releases/production/initial" "$WEB/production"
ln -sfn "$WEB/releases/staging/initial"   "$WEB/staging"

chown -R "$BUILD_USER:$BUILD_USER" "$CI_BASE"
chown -R "$BUILD_USER:caddy"       "$WEB"

# ── CADDY ─────────────────────────────────────────────────────────────────────
#
# Caddy is the origin file server only. It runs behind an nginx reverse proxy
# which handles TLS termination and the Cross-Origin headers required by Godot's
# threaded web export (COOP + COEP).
#
# COOP/COEP must NOT be set here. If Caddy and nginx both emit them, browsers
# receive duplicate headers and treat Cross-Origin Isolation as misconfigured.

log "Configuring Caddy"

cat > /etc/caddy/Caddyfile <<EOF
:8080 {
  encode zstd gzip

  # ── Staging ─────────────────────────────────────────────────────────────────
  # Redirect bare /staging to /staging/ for consistent base-URL behaviour.
  redir /staging /staging/ 308

  handle_path /staging/* {
    root * $WEB/staging

    header /index.html {
      Cache-Control "no-cache"
    }

    header /index.serviceWorker.js {
      Cache-Control "no-store"
    }

    # Prevent search engines from indexing staging builds.
    header {
      X-Robots-Tag "noindex, nofollow, noarchive"
    }

    # SPA fallback: rewrite unknown paths to index.html for client-side routing.
    @spa_fallback {
      not path *.js *.wasm *.pck *.png *.ico *.json *.css *.svg *.webmanifest
      not file
    }
    rewrite @spa_fallback /index.html

    file_server
  }

  # ── Production ──────────────────────────────────────────────────────────────
  handle {
    root * $WEB/production

    header /index.html {
      Cache-Control "no-cache"
    }

    header /index.serviceWorker.js {
      Cache-Control "no-store"
    }

    @spa_fallback {
      not path *.js *.wasm *.pck *.png *.ico *.json *.css *.svg *.webmanifest
      not file
    }
    rewrite @spa_fallback /index.html

    file_server
  }
}
EOF

systemctl enable caddy
systemctl restart caddy

# ── EXPORT TEMPLATES ──────────────────────────────────────────────────────────

log "Installing Godot $GODOT_VERSION export templates"

DEST="/home/$BUILD_USER/.local/share/godot/export_templates/$GODOT_VERSION"
mkdir -p "$DEST"

TMP_TPZ="$(mktemp /tmp/godot-templates.XXXXXX.tpz)"
TMP_DIR="$(mktemp -d /tmp/godot-templates.XXXXXX)"

download_and_verify() {
  local url="$1"
  log "Downloading templates: $url"

  if ! curl \
      -fL \
      --retry 3 \
      --retry-delay 5 \
      --connect-timeout 15 \
      --max-time 1800 \
      --speed-limit 100000 \
      --speed-time 90 \
      "$url" \
      -o "$TMP_TPZ"; then
    log "Download failed: $url"
    return 1
  fi

  local size
  size="$(stat -c%s "$TMP_TPZ")"
  if [[ "$size" -lt "$MIN_TPZ_BYTES" ]]; then
    log "ERROR: archive too small (${size} bytes < ${MIN_TPZ_BYTES} minimum)"
    return 1
  fi

  log "Verifying SHA-256 checksum"
  local actual
  actual="$(sha256sum "$TMP_TPZ" | awk '{print $1}')"
  if [[ "$actual" != "$TEMPLATES_SHA256" ]]; then
    log "ERROR: checksum mismatch"
    log "  expected: $TEMPLATES_SHA256"
    log "  actual:   $actual"
    return 1
  fi

  log "Checksum OK"

  log "Validating archive structure"
  if ! unzip -tq "$TMP_TPZ" >/dev/null; then
    log "ERROR: archive failed integrity check"
    return 1
  fi

  return 0
}

if ! download_and_verify "$GITHUB_TEMPLATES_URL"; then
  log "GitHub download/verify failed; trying SourceForge mirror"
  rm -f "$TMP_TPZ"
  if ! download_and_verify "$SOURCEFORGE_TEMPLATES_URL"; then
    log "ERROR: all template download sources failed"
    rm -rf "$TMP_TPZ" "$TMP_DIR"
    exit 1
  fi
fi

log "Extracting templates to $DEST"
unzip -q "$TMP_TPZ" -d "$TMP_DIR"

if [[ -d "$TMP_DIR/templates" ]]; then
  mv "$TMP_DIR/templates/"* "$DEST/"
else
  mv "$TMP_DIR/"* "$DEST/"
fi

chown -R "$BUILD_USER:$BUILD_USER" "/home/$BUILD_USER/.local"
rm -rf "$TMP_TPZ" "$TMP_DIR"

log "Bootstrap complete"
BOOTSTRAP

# =========================
# VERIFY
# =========================

log "Verifying container setup"

pct exec "$CTID" -- systemctl is-active caddy >/dev/null
pct exec "$CTID" -- id "$BUILD_USER" >/dev/null
pct exec "$CTID" -- sudo -u "$BUILD_USER" godot --headless --version || true

log "Verifying Caddy is serving production and staging"

PROD_CODE=$(curl -so /dev/null  -w "%{http_code}" "http://$IP:8080/"        || true)
REDIR_CODE=$(curl -so /dev/null -w "%{http_code}" "http://$IP:8080/staging" || true)
STAGE_CODE=$(curl -so /dev/null -w "%{http_code}" "http://$IP:8080/staging/" || true)

if [[ "$PROD_CODE" != "200" ]]; then
  echo "[WARN] Production returned HTTP $PROD_CODE — expected 200"
  echo "       Check: pct exec $CTID -- systemctl status caddy"
else
  log "Production healthy (HTTP 200)"
fi

if [[ "$REDIR_CODE" != "308" && "$REDIR_CODE" != "200" ]]; then
  echo "[WARN] /staging returned HTTP $REDIR_CODE — expected 308 or 200"
else
  log "/staging redirect OK (HTTP $REDIR_CODE)"
fi

if [[ "$STAGE_CODE" != "200" ]]; then
  echo "[WARN] Staging returned HTTP $STAGE_CODE — expected 200"
  echo "       Check: pct exec $CTID -- systemctl status caddy"
else
  log "Staging healthy (HTTP 200)"
fi

COOP_CHECK=$(curl -sI "http://$IP:8080/" | grep -i "Cross-Origin-Opener-Policy" || true)
if [[ -n "$COOP_CHECK" ]]; then
  echo "[WARN] Caddy is setting COOP — remove it from the Caddyfile."
  echo "       Duplicate COOP/COEP headers (from both Caddy and nginx) break"
  echo "       Cross-Origin Isolation. nginx must be the sole source of these headers."
  echo "       Fix: pct exec $CTID -- vim /etc/caddy/Caddyfile && pct exec $CTID -- systemctl reload caddy"
else
  log "COOP/COEP not set by Caddy (correct — nginx handles these)"
fi

# =========================
# RUNNER (OPTIONAL)
# =========================

if [[ "$RUNNER_ENABLE" == "1" ]]; then
  if [[ -z "$GITHUB_PAT" || -z "$REPO_URL" ]]; then
    echo "[ERROR] RUNNER_ENABLE=1 requires GITHUB_PAT and REPO_URL"
    exit 1
  fi

  log "Fetching runner registration token from GitHub"
  _REPO_PATH="${REPO_URL#https://github.com/}"
  _TOKEN_RESPONSE="$(curl -fsSL \
    -X POST \
    -H "Authorization: Bearer $GITHUB_PAT" \
    -H "Accept: application/vnd.github+json" \
    "https://api.github.com/repos/${_REPO_PATH}/actions/runners/registration-token")"
  RUNNER_TOKEN="$(echo "$_TOKEN_RESPONSE" | grep '"token"' | head -1 | awk -F'"' '{print $4}')"

  if [[ -z "$RUNNER_TOKEN" ]]; then
    echo "[ERROR] Failed to fetch registration token — check GITHUB_PAT and REPO_URL"
    exit 1
  fi
  log "Registration token fetched (expires in 60 min)"

  log "Installing GitHub Actions runner v${RUNNER_VERSION}"

  pct exec "$CTID" -- env \
    RUNNER_TOKEN="$RUNNER_TOKEN" \
    REPO_URL="$REPO_URL" \
    RUNNER_VERSION="$RUNNER_VERSION" \
    RUNNER_SHA256="$RUNNER_SHA256" \
    BUILD_USER="$BUILD_USER" \
    CTID="$CTID" \
    bash -s <<'RUNNER'
set -euo pipefail

log() { echo "[runner] $*"; }

RUNNER_DIR="/home/$BUILD_USER/runner"
ARCHIVE="actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz"
URL="https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/${ARCHIVE}"

log "Downloading runner archive"
mkdir -p "$RUNNER_DIR"
curl -fL -o /tmp/runner.tar.gz "$URL"

log "Verifying runner checksum"
ACTUAL_SHA="$(sha256sum /tmp/runner.tar.gz | awk '{print $1}')"
if [[ "$ACTUAL_SHA" != "$RUNNER_SHA256" ]]; then
  echo "[runner] ERROR: runner archive checksum mismatch"
  echo "  expected: $RUNNER_SHA256"
  echo "  actual:   $ACTUAL_SHA"
  exit 1
fi
log "Runner checksum OK"

tar xzf /tmp/runner.tar.gz -C "$RUNNER_DIR"
rm -f /tmp/runner.tar.gz
chown -R "$BUILD_USER:$BUILD_USER" "$RUNNER_DIR"

log "Installing runner system dependencies"
bash "$RUNNER_DIR/bin/installdependencies.sh"

runuser -u "$BUILD_USER" -- bash -lc "
  cd '$RUNNER_DIR'
  ./config.sh --unattended \
    --url '$REPO_URL' \
    --token '$RUNNER_TOKEN' \
    --name 'gd-$CTID' \
    --labels 'self-hosted,proxmox,godot,gd-$CTID' \
    --work _work \
    --runasservice \
    --replace
"

cd "$RUNNER_DIR"
./svc.sh install "$BUILD_USER"

# Write a systemd drop-in so the runner unit finds /usr/local/bin/godot.
UNIT_FILE="$(find /etc/systemd/system -maxdepth 1 -name 'actions.runner.*.service' | head -1 || true)"
if [[ -n "$UNIT_FILE" ]]; then
  DROPIN_DIR="${UNIT_FILE%.service}.service.d"
  mkdir -p "$DROPIN_DIR"
  cat > "$DROPIN_DIR/path.conf" <<DROPIN
[Service]
Environment="PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
DROPIN
  systemctl daemon-reload
  log "Systemd PATH override written for $(basename "$UNIT_FILE")"
else
  log "WARNING: could not detect runner unit file — PATH override not applied."
  log "Godot may not be found during workflow runs. Set PATH explicitly in your workflow."
fi

./svc.sh start
log "Runner started"
RUNNER

else
  log "Runner skipped (RUNNER_ENABLE != 1)"
fi

# =========================
# RESULT
# =========================

echo ""
echo "=============================="
echo "CONTAINER READY"
echo "CTID:       $CTID"
echo "IP:         $IP"
echo "Production: http://$IP:8080/"
echo "Staging:    http://$IP:8080/staging/"
echo ""
echo "Required nginx headers (must be set by nginx, NOT by Caddy):"
echo "  Cross-Origin-Opener-Policy:   same-origin"
echo "  Cross-Origin-Embedder-Policy: require-corp"
echo "=============================="
