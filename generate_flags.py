#!/usr/bin/env python3
import argparse, base64, json, secrets
from pathlib import Path
from Cryptodome.Cipher import AES

CHAL_DIRS = {
    "crypto": "challenges/crypto_challenge",
    "reversing": "challenges/reversing_challenge",
    "forensics": "challenges/forensics_challenge",
    "stego": "challenges/stego_challenge",
    "weblogic": "challenges/web_logic_challenge",
}

def make_flag():
    return f"wvu6or7{{{secrets.token_hex(12)}}}"

def encrypt_flag(key: bytes, flag: str) -> str:
    iv = secrets.token_bytes(12)
    cipher = AES.new(key, AES.MODE_GCM, nonce=iv)
    ct, tag = cipher.encrypt_and_digest(flag.encode())
    return base64.b64encode(iv + tag + ct).decode()

def main():
    p = argparse.ArgumentParser()
    p.add_argument("--out-dir", required=True, help="path to ./challenges")
    args = p.parse_args()

    meta = {}
    Path("flags").mkdir(exist_ok=True, parents=True)

    for short, rel in CHAL_DIRS.items():
        key = secrets.token_bytes(32)
        flag = make_flag()
        enc = encrypt_flag(key, flag)
        Path(rel).mkdir(parents=True, exist_ok=True)
        (Path(rel) / "flag.enc").write_text(enc)
        meta[short] = {
            "flag_plain": flag,
            "key_b64": base64.b64encode(key).decode(),
            "flag_enc_b64": enc
        }
        print(f"[+] {short}: {flag}")

    Path("flags/meta.json").write_text(json.dumps(meta, indent=2))
    print("[!] flags/meta.json written. DO NOT COMMIT THIS FILE.")

if __name__ == "__main__":
    main()
