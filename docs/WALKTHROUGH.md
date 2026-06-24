# 📘 Build Walkthrough — flask-cicd-gitops-platform

A step-by-step guide to building this end-to-end DevOps platform from scratch,
written for a journey from **beginner → expert**. Follow along stage by stage.

| Setting | Value |
|---------|-------|
| Repository | `flask-cicd-gitops-platform` |
| GitHub owner | `Ike-DevCloudIQ` |
| Container image | `emekaezedozie276/flask-app` (Docker Hub) |
| Cloud | AWS (`eu-west-1`) |

---

## 🗺️ Stage map

| # | Stage | Purpose | Status |
|---|-------|---------|--------|
| 0 | Repo bootstrap | Structure, `.gitignore`, README | ✅ Done |
| 1 | Flask app + tests | The application to ship | ✅ Done |
| 2 | Docker | Containerize (hardened image) | ✅ Done |
| 3 | Kubernetes | Deploy manifests (Kustomize) | ✅ Done |
| 4 | Terraform | Provision AWS infra (modular) | ✅ Done |
| 5 | Ansible | Configure EC2 (dynamic inventory) | ✅ Done |
| 6 | Jenkins CI | Build · scan · push · update manifest | ✅ Done |
| 7 | ArgoCD | GitOps continuous delivery | ⏳ |
| 8 | Wiring + hardening | End-to-end glue, docs, security | ⏳ |

---

## ✅ Stage 0 — Repository bootstrap

**Goal:** establish a clean, modular monorepo so each tool lives in its own domain folder.

### Steps
1. Choose a descriptive repo name → `flask-cicd-gitops-platform`.
2. Create the folder layout (see [Project structure](#-project-structure)).
3. Add a hardened `.gitignore` that blocks secrets and state files.
4. Write a README skeleton with the architecture diagram and a build-status table.

### Why it matters
- **Separation of concerns** — `app/`, `docker/`, `terraform/`, `ansible/`, `jenkins/`, `kubernetes/`, `argocd/` are independently ownable.
- The original repo committed a private key (`*.pem`). Our `.gitignore` blocks
  `*.pem`, `*.key`, `*.tfstate`, `.env`, and `*.tfvars` to prevent secret leaks.

### Files produced
- `.gitignore`
- `README.md`

---

## ✅ Stage 1 — Flask application + tests

**Goal:** a small, **testable**, production-ready web app.

### Steps
1. Implement `app/app.py` using the **application-factory pattern** (`create_app()`).
2. Add a `/health` endpoint for Kubernetes liveness/readiness probes.
3. Pin runtime deps in `requirements.txt` (`Flask`, `gunicorn`).
4. Separate test deps in `requirements-dev.txt` (`pytest`).
5. Add a Jinja template + CSS for the UI.
6. Write unit tests in `app/tests/test_app.py`.

### Run it locally
```bash
cd app
python -m venv .venv && source .venv/bin/activate
pip install -r requirements-dev.txt
pytest                # ✅ 2 passed
python app.py         # http://localhost:5000
```

### Why it matters
| Original repo | Our enhancement |
|---------------|-----------------|
| Empty `FinalProject/` | Real, tested Flask app |
| `app.run()` dev server only | `gunicorn` (production WSGI) + `/health` probe |
| No tests | Unit tests that will gate the CI pipeline |

### Files produced
- `app/app.py`
- `app/requirements.txt`, `app/requirements-dev.txt`
- `app/templates/index.html`, `app/static/style.css`
- `app/tests/test_app.py`

---

## ✅ Stage 2 — Docker (containerization)

**Goal:** a small, secure container image.

### Completed
1. ✅ Single-stage `Dockerfile` (pragmatic approach for macOS Docker).
2. ✅ Non-root user (`app`).
3. ✅ `gunicorn` as the entrypoint.
4. ✅ `HEALTHCHECK` instruction for K8s probes.
5. ✅ `.dockerignore` to keep build context lean.
6. ✅ **SSL workaround:** added `--trusted-host` flags for macOS Docker Desktop.

### Validation
```bash
docker build -t emekaezedozie276/flask-app:stage2 -f docker/Dockerfile .
docker run -p 5000:5000 emekaezedozie276/flask-app:stage2
curl http://localhost:5000/health      # ✅ 200 {"status":"healthy"}
curl http://localhost:5000/            # ✅ 200 HTML page
docker tag emekaezedozie276/flask-app:stage2 emekaezedozie276/flask-app:v0.2.0
```

---

## ✅ Stage 3 — Kubernetes (Kustomize)

**Goal:** declarative deployment manifests with environment overlays.

### Planned steps
1. `base/` manifests: `namespace`, `deployment`, `service`, `kustomization`.
2. Add liveness/readiness probes pointing at `/health`.
3. Set resource requests/limits.
4. `overlays/dev` and `overlays/prod` for environment-specific config.

---

## ✅ Stage 4 — Terraform (AWS infrastructure)

**Goal:** reproducible AWS infra via real, reusable modules.

### Planned steps
1. S3 remote backend with **native state locking** (no DynamoDB).
2. `modules/network` — VPC `10.0.0.0/16`, public `10.0.1.0/24` (us-east-1a),
   private `10.0.10.0/24` (us-east-1b), IGW, route tables.
3. `modules/security` — security groups (SSH, HTTP, Jenkins 8080).
4. `modules/compute` — EC2 Jenkins **master** + **slave**.
5. `modules/notifications` — SNS topic + CloudWatch alarms (email).
6. `outputs.tf` — public IPs for Ansible.

---

## ✅ Stage 5 — Ansible (configuration management)

**Goal:** configure the EC2 instances automatically.

### Planned steps
1. `aws_ec2.yml` **dynamic inventory** (discovers hosts by tag).
2. Roles: `common`, `docker`, `java`, `jenkins-master`, `jenkins-slave`.
3. `site.yml` playbook to orchestrate the roles.

---

## ✅ Stage 6 — Jenkins CI

**Goal:** automated build → scan → push → manifest update.

### What was built
1. `jenkins/Jenkinsfile` — 7-stage declarative pipeline on a slave agent.
2. `jenkins/shared-library/vars/` — 5 reusable Groovy steps: `buildImage`, `scanImage`, `pushImage`, `updateManifest`, `pushManifest`.
3. Images tagged with `BUILD_NUMBER` (never `latest`).
4. Trivy scans image before push — fails only on CRITICAL CVEs with available fixes (`--ignore-unfixed`).
5. Manifest commit pushed back to `main` with `[skip ci]` to trigger ArgoCD without looping.

### Issues fixed during execution
| Issue | Root cause | Fix |
|---|---|---|
| `Library expected to contain src or vars` | Library path not set in Jenkins | Set Library Path to `jenkins/shared-library` in Global Pipeline Libraries |
| Agent offline | Wrong credential type selected for node | Created `jenkins-slave-ssh` (SSH Username with private key), set host verification to Non verifying |
| `Permission denied` on `/opt/jenkins-agent` | Directory owned by root | `sudo chown -R ec2-user:ec2-user /opt/jenkins-agent` on slave |
| `install: cannot create /usr/local/bin/trivy` | Jenkins user cannot write system dirs | Trivy now installs to `$WORKSPACE/.bin` |
| Pipeline failed on scan | Base image CVEs with no available fix | Added `--ignore-unfixed` to Trivy — only blocks on patchable CRITICAL CVEs |
| Docker Hub unauthorized | Account password used instead of PAT | Updated `dockerhub-credentials` with Docker Hub personal access token |

### Validated pipeline run (build #7)
- ✅ Checkout — commit `ad075ed` on slave agent
- ✅ Test — `2 passed` (pytest)
- ✅ Build — `emekaezedozie276/flask-app:7` built via Docker
- ✅ Scan — Trivy 0.71.2 ran, no patchable CRITICALs, report archived
- ✅ Push — image pushed to Docker Hub
- ✅ Update Manifest — image tag updated in `kubernetes/overlays/dev/deployment-patch.yaml`
- ✅ Publish Manifest — `git push` with `[skip ci]` commit back to `main`
- ✅ Result: `Finished: SUCCESS`

---

## ⏳ Stage 7 — ArgoCD (GitOps CD)

**Goal:** the cluster continuously reconciles to match Git.

### Planned steps
1. `argocd/application.yaml` pointing at `kubernetes/overlays/<env>`.
2. `argocd/project.yaml` to scope permissions.
3. Enable automated sync (prune + self-heal).

---

## ⏳ Stage 8 — Wiring & hardening

**Goal:** make it cohesive and safe.

### Planned steps
1. End-to-end smoke test of the full pipeline.
2. Security review (secrets, RBAC, image scanning gates).
3. Final docs + architecture diagram in `docs/`.
4. `git init` + push to `github.com/Ike-DevCloudIQ/flask-cicd-gitops-platform`.

---

## 📂 Project structure

```
flask-cicd-gitops-platform/
├── app/            # Flask application + unit tests
├── docker/         # Dockerfile + .dockerignore
├── terraform/      # AWS infrastructure (modular)
├── ansible/        # EC2 configuration management
├── jenkins/        # CI pipeline + shared library
├── kubernetes/     # Kustomize base + overlays
├── argocd/         # GitOps Application definitions
└── docs/           # Architecture, diagrams, this walkthrough
```

---

> 🔄 This document is updated as each stage completes. Current position: **Stage 6 done — Stage 7 next.**

## 👤 Author

**Ikenna Ubah** — DevOps & Platform Engineer

[![GitHub](https://img.shields.io/badge/GitHub-Ike--DevCloudIQ-181717?logo=github)](https://github.com/Ike-DevCloudIQ)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-Ikenna%20Ubah-0A66C2?logo=linkedin&logoColor=white)](https://www.linkedin.com/in/ikenna2/)

> ⭐ If you found this project useful or insightful, please consider starring the repository.
