#!/usr/bin/env bash
# install.sh
# One-shot installer for the ctf-vm-installer scaffold.
# - Installs docker + docker compose plugin (if missing)
# - Installs pycryptodome for the generator
# - Runs generate_flags.py to create encrypted flags and flags/meta.json
# - Writes docker-compose.override.yml with CHAL_KEY_B64 env vars (not committed)
# - Builds and starts containers with `docker compose up --build -d`
#
# Run as: chmod +x install.sh && sudo ./install.sh
set -euo pipefail

# Run from script directory
here="$(cd "$(dirname "$0")" && pwd)"
cd "$here"

echo
echo "[*] CTF VM Installer starting from: $here"
echo

# Helper: echo+exit on error
err() { echo "[ERROR] $*" >&2; exit 1; }

# 1) Ensure apt package index is available for installs (Debian/Ubuntu)
need_apt_install=false
if command -v apt-get >/dev/null 2>&1; then
  need_apt_install=true
fi

# 2) Install Docker (docker.io) if necessary
if ! command -v docker >/dev/null 2>&1; then
  if [ "$need_apt_install" = true ]; then
    echo "[*] Docker not found. Installing docker.io (apt)..."
    sudo apt-get update -y
    sudo apt-get install -y docker.io
    sudo systemctl enable --now docker || true
  else
    err "docker not found and automatic install not supported on this OS. Please install Docker manually."
  fi
else
  echo "[*] Docker detected: $(docker --version | sed -n '1p')"
fi

# 3) Ensure docker compose v2 plugin is available (i.e., `docker compose` works)
if ! docker compose version >/dev/null 2>&1; then
  if [ "$need_apt_install" = true ]; then
    echo "[*] docker compose plugin not found. Installing docker-compose-plugin (apt)..."
    sudo apt-get update -y
    sudo apt-get install -y docker-compose-plugin
  else
    echo "[!] docker compose plugin not found. Please install the appropriate compose plugin for your OS."
  fi
else
  echo "[*] Docker Compose detected: $(docker compose version | head -n1)"
fi

# 4) Ensure Python3 is installed
if ! command -v python3 >/dev/null 2>&1; then
  if [ "$need_apt_install" = true ]; then
    echo "[*] python3 not found. Installing python3..."
    sudo apt-get update -y
    sudo apt-get install -y python3
  else
    err "python3 not found. Please install python3."
  fi
fi

# 5) Ensure pip3 exists (try install if missing)
if ! command -v pip3 >/dev/null 2>&1; then
  if [ "$need_apt_install" = true ]; then
    echo "[*] pip3 not found. Installing python3-pip..."
    sudo apt-get update -y
    sudo apt-get install -y python3-pip
  else
    err "pip3 not found. Please install pip3."
  fi
fi

# 6) Ensure pycryptodome is present (used by generate_flags.py)
echo "[*] Ensuring pycryptodome is installed for Python..."
if ! python3 -c "import Crypto" >/dev/null 2>&1; then
  # try user install first
  pip3 install --user pycryptodome || sudo pip3 install pycryptodome
fi

# 7) Create flags dir
mkdir -p flags

# 8) Generate flags (script must exist)
if [ ! -f "./generate_flags.py" ]; then
  err "generate_flags.py not found in repository root. Please ensure file exists."
fi

echo "[*] Generating encrypted flags (this will write flags/meta.json and flag.enc files)..."
python3 generate_flags.py --out-dir ./challenges

# Verify meta.json
if [ ! -f "flags/meta.json" ]; then
  err "flags/meta.json not found after running generate_flags.py. Aborting."
fi

# 9) Build docker-compose.override.yml from flags/meta.json
echo "[*] Generating docker-compose.override.yml with per-service CHAL_KEY_B64 (file is NOT committed)."
python3 - <<'PY'
import json,sys,os
meta_path = "flags/meta.json"
if not os.path.exists(meta_path):
    print("[ERROR] flags/meta.json missing", file=sys.stderr)
    sys.exit(2)
m = json.load(open(meta_path))
services = ["crypto","reversing","forensics","stego","weblogic"]
lines = ["version: '3.8'", "services:"]
for s in services:
    if s not in m:
        print(f"[WARN] {s} not in meta.json; skipping", file=sys.stderr)
        continue
    key = m[s]['key_b64']
    lines.append(f"  {s}:")
    lines.append("    environment:")
    lines.append(f"      - CHAL_KEY_B64={key}")
open("docker-compose.override.yml","w").write("\n".join(lines) + "\n")
print("[*] Wrote docker-compose.override.yml")
PY

# Ensure override file is not accidentally added to git (we include it in .gitignore normally)
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  if ! grep -qxF "docker-compose.override.yml" .gitignore 2>/dev/null; then
    echo "docker-compose.override.yml" >> .gitignore
    git add .gitignore >/dev/null 2>&1 || true
  fi
fi

# 10) Build and run with docker compose
echo "[*] Building and starting containers (may require sudo) ..."
if ! sudo docker compose up --build -d; then
  err "docker compose failed. See 'sudo docker compose logs' for details."
fi

echo
echo "[*] Success — containers are starting."
echo "    -> Crypto:     http://localhost:8001"
echo "    -> Reversing:  http://localhost:8002"
echo "    -> Forensics:  http://localhost:8003"
echo "    -> Stego:      http://localhost:8004"
echo "    -> Web-Logic:  http://localhost:8005"
echo
echo "[!]"
echo "    NOTE: flags/meta.json contains plaintext flags & AES keys. KEEP IT PRIVATE."
echo "    The installer writes docker-compose.override.yml locally; it should NOT be committed."
echo

# 11) Quick status
echo "[*] docker compose ps:"
sudo docker compose ps

exit 0
