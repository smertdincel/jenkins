from flask import Flask, jsonify
app = Flask(__name__)

@app.route("/")
def home():
    return "Merhaba! CI/CD + Kubernetes (Minikube) üzerinde Flask 🎉"

@app.route("/health")
def health():
    return jsonify(status="ok")
PY