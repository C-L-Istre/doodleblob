# Godot CLI Server — Deployment Quickstart

This script provisions a Proxmox LXC container that builds and serves your Godot web export on every commit to `main`/`master`. A GitHub Actions self-hosted runner inside the container handles the build pipeline.

---

## Prerequisites

- A Proxmox host with the Fedora 43 LXC template available
- A GitHub Personal Access Token (PAT) with the `repo` scope
- A free container ID (`<CTID>`) on your Proxmox host

---

## Step 1 — Request a runner registration token

Registration tokens are single-use and expire **60 minutes** after being issued. Request one immediately before running the deploy script to avoid a timeout.

Replace `<PAT>`, `<GIT_USER>`, and `<REPO>` with your values:

```bash
curl -X POST \
  -H "Authorization: Bearer <PAT>" \
  -H "Accept: application/vnd.github+json" \
  https://api.github.com/repos/<GIT_USER>/<REPO>/actions/runners/registration-token
```

The response looks like this:

```json
{
  "token": "AXXXXXXXXXXXXXXXXXXXXXXXXXX",
  "expires_at": "2026-01-01T00:00:00.000-00:00"
}
```

Copy the `token` value. Do not include the surrounding quotes.

---

## Step 2 — Deploy the container

Run the following on your Proxmox host. Paste the token from Step 1 into `RUNNER_TOKEN`.

```bash
sudo RUNNER_ENABLE=1 \
     RUNNER_TOKEN="<PASTE_TOKEN_HERE>" \
     REPO_URL="https://github.com/<GIT_USER>/<REPO>" \
     bash godot-ci-deploy.sh <CTID>
```

`MAC` is optional. Set it if you want a fixed MAC address for a DHCP reservation:

```bash
sudo RUNNER_ENABLE=1 \
     RUNNER_TOKEN="<PASTE_TOKEN_HERE>" \
     REPO_URL="https://github.com/<GIT_USER>/<REPO>" \
     MAC="xx:xx:xx:xx:xx:xx" \
     bash godot-ci-deploy.sh <CTID>
```

Provisioning takes 5–10 minutes depending on download speed. The script prints the container IP and a confirmation when complete.

---

## Step 3 — Verify

Once provisioning finishes, confirm the runner appears in your repository:

**GitHub → Repository → Settings → Actions → Runners**

It should show as **Idle**. The next push to `main` or `master` will trigger a build.

---

## Re-registering the runner

If registration fails (e.g. the token expired before the script finished), re-register without reprovisioning. Request a fresh token using Step 1, then run:

```bash
pct exec <CTID> -- env \
  RUNNER_TOKEN="<FRESH_TOKEN>" \
  REPO_URL="https://github.com/<GIT_USER>/<REPO>" \
  CTID="<CTID>" \
  bash -s << 'EOF'
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
cd '$RUNNER_DIR'
./svc.sh install godot
./svc.sh start
EOF
```

---

## Notes

- The game is served at `http://<CONTAINER_IP>:8080`
- Builds are triggered automatically on every push to `main` or `master`
- The 10 most recent builds are retained on disk; older ones are deleted automatically
- Required browser headers (`Cross-Origin-Opener-Policy`, `Cross-Origin-Embedder-Policy`) are set by Caddy and are verified on each deploy — these are mandatory for Godot's multithreaded web export
<<<<<<< Updated upstream
- WE'RE BACK!!!!!
=======
>>>>>>> Stashed changes
