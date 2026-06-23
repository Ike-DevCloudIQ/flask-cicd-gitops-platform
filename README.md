# 🚀 flask-cicd-gitops-platform

An end-to-end DevOps platform that builds, secures, ships, and deploys a Flask
web application using Infrastructure as Code, configuration management, CI, and
GitOps-based continuous delivery.

```
GitHub ──> Jenkins (build · Trivy scan · push) ──> Docker Hub
   │                         │
   │                         └─> update K8s manifest (image tag)
   ▼                                         │
Terraform ─> AWS (VPC, EC2, S3, SNS)         ▼
   │                                   ArgoCD (GitOps) ──> Kubernetes
   └─> Ansible (configure EC2 via dynamic inventory)
```

## 🧰 Tech stack

| Layer | Tool |
|-------|------|
| Application | Python · Flask |
| Containerization | Docker |
| Orchestration | Kubernetes (Kustomize) |
| Infrastructure as Code | Terraform (AWS) |
| Configuration Management | Ansible (dynamic inventory) |
| Continuous Integration | Jenkins + shared library |
| Image Security | Trivy |
| Continuous Delivery | ArgoCD (GitOps) |

## 📂 Repository structure

```
flask-cicd-gitops-platform/
├── app/            # Flask application + unit tests
├── docker/         # Dockerfile + .dockerignore
├── terraform/      # AWS infrastructure (modular)
├── ansible/        # EC2 configuration management
├── jenkins/        # CI pipeline + shared library
├── kubernetes/     # Kustomize base + overlays
├── argocd/         # GitOps Application definitions
└── docs/           # Architecture & diagrams
```

## 🏗️ Build status

| Stage | Status |
|-------|--------|
| 0 · Repo bootstrap | ✅ |
| 1 · Flask app + tests | ✅ |
| 2 · Docker | ⏳ |
| 3 · Kubernetes | ⏳ |
| 4 · Terraform | ⏳ |
| 5 · Ansible | ⏳ |
| 6 · Jenkins CI | ⏳ |
| 7 · ArgoCD | ⏳ |

## ▶️ Run the app locally

```bash
cd app
python -m venv .venv && source .venv/bin/activate
pip install -r requirements-dev.txt
pytest                       # run tests
python app.py                # http://localhost:5000
```
