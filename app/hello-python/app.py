from flask import Flask
app = Flask(__name__)

@app.route("/")
@app.route("/jenkins")
def home():
    return "Hello World from Flask running on EKS via Helm & Jenkins! JENKINS PROD TEST C TAKE 2"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)

