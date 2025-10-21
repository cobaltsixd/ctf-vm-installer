from flask import Flask, request, jsonify, send_file, abort
from Crypto.Cipher import AES
import base64, os

app = Flask(__name__)
FLAG_ENC = open("flag.enc").read().strip()

@app.get("/")
def index():
    return open("challenge.txt").read()

@app.get("/download")
def download():
    if not os.path.exists("hidden.png"):
        abort(404, "instructor: add hidden.png to this folder")
    return send_file("hidden.png", as_attachment=True)

def decrypt_flag():
    key = base64.b64decode(os.environ["CHAL_KEY_B64"])
    blob = base64.b64decode(FLAG_ENC)
    iv, tag, ct = blob[:12], blob[12:28], blob[28:]
    return AES.new(key, AES.MODE_GCM, nonce=iv).decrypt_and_verify(ct, tag).decode()

@app.post("/submit")
def submit():
    candidate = (request.get_json() or {}).get("candidate","").strip()
    # TODO: replace with actual expected message from your stego
    if candidate == "hidden-string":
        return jsonify({"status":"correct","flag":decrypt_flag()})
    return jsonify({"status":"incorrect"})
