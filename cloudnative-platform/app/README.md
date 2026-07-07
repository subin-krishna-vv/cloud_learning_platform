# Simple Flask App - Quick Start

## Install Dependencies

```bash
cd cloudnative-platform/app
pip install -r requirements.txt
```

## Run the App

### Locally

```bash
python3 src/main.py
```

### In Docker

```bash
docker build -t flask-app:1.0 .
docker run -p 5000:5000 flask-app:1.0
```

The app will start at: `http://localhost:5000`

---

## Available Endpoints

### Health Checks (Kubernetes Probes)

**Liveness Probe** - Is the app running?
```bash
curl http://localhost:5000/health/live
```
Response: `{"status": "alive"}`

**Readiness Probe** - Is the app ready to serve?
```bash
curl http://localhost:5000/health/ready
```
Response: `{"status": "ready"}`

---

### Core API Endpoints

**Get Info** - Root endpoint
```bash
curl http://localhost:5000/
```

**Get Status** - Application status
```bash
curl http://localhost:5000/api/v1/status
```

**Get Items** - Returns a hardcoded list of items
```bash
curl http://localhost:5000/items
```

**Process Data** - POST endpoint for processing
```bash
curl -X POST http://localhost:5000/api/v1/process \
  -H "Content-Type: application/json" \
  -d '{"data":"hello"}'
```

---

## How This App Helps You Learn

This is a **bare minimum Flask app** that you can extend as you learn:

- **Phase 1-2 (K8s Basics)**: Health checks are ready for deployment
- **Phase 3 (Vault)**: Add API key validation from headers
- **Phase 4 (Security)**: Add request logging and error handling
- **Phase 5 (Helm)**: Externalize config to environment variables
- **Phase 6 (Tracing)**: Add OpenTelemetry instrumentation
- **Phase 7 (Prometheus/SLI)**: Add `/metrics` endpoint and counters
- **Phase 8 (Kubecost)**: Add resource-aware metadata
- **Phase 9 (Automation)**: Write scripts to call these endpoints

---

## Dockerfile Details

The Dockerfile follows production best practices:

**Multi-stage Build**
- Stage 1 (Builder): Installs Python dependencies
- Stage 2 (Runtime): Only includes necessary files, reducing image size

**Non-root User**
- Creates `appuser` with UID 999
- Container runs as non-root for security

**Pinned Base Image**
- Uses `python:3.11.7-slim` (specific version and tag)
- Ensures reproducible builds across environments

**Image Size**
- ~136 MB (due to slim Python image and multi-stage optimization)
