from flask import Flask, request, jsonify
from Crypto.Cipher import AES
import base64, os

app = Flask(__name__)
FLAG_ENC = open("flag.enc").read().strip()

@app.get("/")
def index():
    return open("challenge.txt").read()

@app.get("/story")
def story():
    return "Alice moves 3 items, Bob swaps 2, Carol returns 1. Who holds the red box?"

def decrypt_flag():
    key = base64.b64decode(os.environ["CHAL_KEY_B64"])
    blob = base64.b64decode(FLAG_ENC)
    iv, tag, ct = blob[:12], blob[12:28], blob[28:]
    return AES.new(key, AES.MODE_GCM, nonce=iv).decrypt_and_verify(ct, tag).decode()

@app.post("/submit")
def submit():
    ans = (request.get_json() or {}).get("answer","").strip().lower()
    # TODO: adjust puzzle & correct answer
    if ans == "alice":
        return jsonify({"status":"correct","flag":decrypt_flag()})
    return jsonify({"status":"incorrect"})
