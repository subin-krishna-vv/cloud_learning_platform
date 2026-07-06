# Cloud-Native GitOps Learning Platform

A learning project with a simple Flask application.

---

## 🚀 Quick Start

### Install & Run the Flask App

```bash
cd app
pip install -r requirements.txt
python3 src/main.py
```

App starts at: **`http://localhost:5000`**

---

## 📡 API Endpoints

### Health Checks

**Liveness Probe**
```bash
curl http://localhost:5000/health/live
```
Response: `{"status": "alive"}`

**Readiness Probe**
```bash
curl http://localhost:5000/health/ready
```
Response: `{"status": "ready"}`

---

### Core Endpoints

**Root**
```bash
curl http://localhost:5000/
```
Response: `{"application": "flask-app", "message": "Cloud-Native Learning Platform"}`

**Status**
```bash
curl http://localhost:5000/api/v1/status
```
Response: `{"status": "operational", "message": "App is running"}`

**Process Data** (POST)
```bash
curl -X POST http://localhost:5000/api/v1/process \
  -H "Content-Type: application/json" \
  -d '{"data":"hello"}'
```
Response: `{"input": "hello", "output": "HELLO", "status": "success"}`

---

## 📂 Project Structure

```
cloudnative-platform/
├── app/                    # Flask application
│   ├── src/main.py        # Main app
│   ├── requirements.txt    # Dependencies
│   └── README.md           # App details
├── helm/                   # Helm charts
├── gitops/                 # ArgoCD manifests
├── vault/                  # Vault setup
├── security/               # RBAC, Kyverno, Trivy
├── observability/          # Prometheus, Grafana, Tempo
├── kubecost/               # Cost monitoring
├── automation/             # Python scripts
├── .github/workflows/      # CI/CD
├── docs/                   # Documentation
└── README.md
```

---

**App Ready**: Run `cd app && python3 src/main.py` to start!
