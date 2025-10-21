# Instructor Notes

## Flag generation & secrets
- Run `./install.sh` to generate flags and start services.
- Flags are encrypted into each `flag.enc`.
- `flags/meta.json` contains plaintext flags + AES keys. **Do not commit it**; delete/move it before handing VMs to students.

## Keys injection
- `install.sh` writes `docker-compose.override.yml` with `CHAL_KEY_B64` per service. This file is ignored by git.

## Reset/regenerate flags
```bash
python3 generate_flags.py --out-dir ./challenges
sudo docker compose build --no-cache
sudo docker compose up -d
