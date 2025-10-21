from flask import Flask, request, send_file, jsonify
from Cryptodome.Cipher import AES
import subprocess, base64, os
app = Flask(__name__)
FLAG_ENC = open("flag.enc").read().strip()
@app.get("/")
def index(): return open("challenge.txt").read()
@app.get("/download")
def download(): return send_file("checker", as_attachment=True)
def decrypt_flag():
    key = base64.b64decode(os.environ["CHAL_KEY_B64"])
    blob = base64.b64decode(FLAG_ENC)
    iv, tag, ct = blob[:12], blob[12:28], blob[28:]
    return AES.new(key, AES.MODE_GCM, nonce=iv).decrypt_and_verify(ct, tag).decode()
@app.post("/submit")
def submit():
    guess = (request.get_json() or {}).get("guess","")
    try:
        r = subprocess.run(["./checker", guess], capture_output=True, timeout=3)
        if b"OK" in r.stdout: return jsonify({"status":"correct","flag":decrypt_flag()})
        return jsonify({"status":"incorrect"})
    except Exception as e:
        return jsonify({"status":"error","msg":str(e)}),500
