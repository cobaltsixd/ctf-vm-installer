from flask import Flask, request, jsonify, abort, send_file
from Crypto.Cipher import AES
import base64, os, os.path

app = Flask(__name__)
FLAG_ENC = open("flag.enc").read().strip()

@app.get("/")
def index():
    return open("challenge.txt").read()

@app.get("/download")
def download():
    if not os.path.exists("hidden.pcap"):
        abort(404, "instructor: add hidden.pcap to this folder")
    return send_file("hidden.pcap", as_attachment=True)

def decrypt_flag():
    key_b64 = os.environ.get("CHAL_KEY_B64")
    if not key_b64: return None
    key = base64.b64decode(key_b64)
    blob = base64.b64decode(FLAG_ENC)
    iv, tag, ct = blob[:12], blob[12:28], blob[28:]
    return AES.new(key, AES.MODE_GCM, nonce=iv).decrypt_and_verify(ct, tag).decode()

@app.post("/submit")
def submit():
    candidate = (request.get_json() or {}).get("candidate","").strip()
    # TODO: replace with your actual expected extraction string
    if candidate == "extract-me":
        flag = decrypt_flag()
        return jsonify({"status":"correct","flag":flag}) if flag else (jsonify({"status":"error"}),500)
    return jsonify({"status":"incorrect"})
