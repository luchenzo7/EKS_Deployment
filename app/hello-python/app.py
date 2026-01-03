from flask import Flask, Response, request
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
import time

app = Flask(__name__)

REQUEST_COUNT = Counter(
    "http_requests_total",
    "Total HTTP requests",
    ["method", "endpoint", "http_status"]
)

REQUEST_LATENCY = Histogram(
    "http_request_duration_seconds",
    "HTTP request latency in seconds",
    ["endpoint"]
)

@app.route("/")
@app.route("/jenkins")
def home():
    start = time.time()
    status_code = 200
    try:
        return "Hello World from Flask running on EKS via Helm & Jenkins! JENKINS PROD TEST C TAKE 3"
    finally:
        endpoint = request.path
        REQUEST_COUNT.labels(request.method, endpoint, str(status_code)).inc()
        REQUEST_LATENCY.labels(endpoint).observe(time.time() - start)

@app.route("/healthz")
def healthz():
    return "ok", 200

@app.route("/metrics")
def metrics():
    return Response(generate_latest(), mimetype=CONTENT_TYPE_LATEST)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)


