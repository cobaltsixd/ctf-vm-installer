
---

## `install.sh`
```bash
#!/usr/bin/env bash
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
cd "$here"

echo "[*] Checking dependencies..."
if ! command -v docker >/dev/null 2>&1; then
  echo "[*] Installing docker..."
  sudo apt-get update
  sudo apt-get install -y docker.io
fi
if ! docker compose version >/dev/null 2>&1; then
  echo "[*] Installing docker compose plugin..."
  sudo apt-get install -y docker-compose-plugin
fi
if ! python3 -c "import Crypto" >/dev/null 2>&1; then
  echo "[*] Installing pycryptodome..."
  pip3 install pycryptodome
fi

mkdir -p flags
echo "[*] Generating encrypted flags..."
python3 generate_flags.py --out-dir ./challenges

# Build docker-compose.override.yml dynamically from flags/meta.json
echo "[*] Writing docker-compose.override.yml with per-challenge keys (not committed)..."
python3 - <<'PY'
import json, os, textwrap
meta = json.load(open('flags/meta.json'))
def env_block(name):
    return f"""  {name}:
    environment:
      - CHAL_KEY_B64={meta[name]['key_b64']}
"""
override = ["version: '3.8'", "services:"]
for name in ["crypto","reversing","forensics","stego","weblogic"]:
    override.append(env_block({
        "crypto":"crypto",
        "reversing":"reversing",
        "forensics":"forensics",
        "stego":"stego",
        "weblogic":"weblogic"
    }[name]))
open("docker-compose.override.yml","w").write("\n".join(override))
PY

echo "[*] Bringing up services..."
sudo docker compose up --build -d

echo "[*] Done."
echo "    -> Crypto:     http://localhost:8001"
echo "    -> Reversing:  http://localhost:8002"
echo "    -> Forensics:  http://localhost:8003"
echo "    -> Stego:      http://localhost:8004"
echo "    -> Web-Logic:  http://localhost:8005"
echo "[!] Keep flags/meta.json private. Delete it from student machines."
