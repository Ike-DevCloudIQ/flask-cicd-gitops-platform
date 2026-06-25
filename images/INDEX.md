# 📸 Evidence Gallery Index

Welcome to the visual portfolio of **flask-cicd-gitops-platform**—a complete, production-ready DevOps system built end-to-end.

This folder contains screenshots, command outputs, and visual proof for each stage of development. Perfect for interviews, portfolio reviews, and demonstrating your engineering depth to recruiters.

---

## 🗂️ Quick Navigation

### [Stage 0: Repository Bootstrap](./stage-0-bootstrap/)
✅ **What it proves:** Clean DevOps project structure with security from day one.
- Repository organization (separated by domain)
- .gitignore blocking secrets (no *.pem, *.key, .env tracked)
- GitHub repository setup
- Architecture diagram in README

**Key files:**
- `01-repo-structure.png` — Folder hierarchy showing separation of concerns
- `02-gitignore.png` — Secret patterns blocked
- `03-github-repo.png` — Public GitHub repository
- `04-readme-architecture.png` — Architecture diagram

---

### [Stage 1: Flask Application + Tests](./stage-1-flask-app/)
✅ **What it proves:** Clean, tested Python code with health checks and proper error handling.
- Flask application code (routes, health endpoint)
- Unit tests (pytest)
- App running locally on localhost:5000
- All tests passing
- Browser connectivity proof

**Key files:**
- `02-test-code.png` — Test suite with multiple test cases
- `04-tests-passing.png` — `pytest -v` showing 100% pass rate
- `06-health-endpoint.png` — Health check endpoint responding correctly

---

### [Stage 2: Docker Containerization](./stage-2-docker/)
✅ **What it proves:** Secure container images with integrated security scanning.
- Dockerfile with non-root user, layer optimization
- Successful image build
- **Trivy security scan** (vulnerability assessment)
- Image pushed to Docker Hub registry
- Public registry visibility

**Key files:**
- `01-dockerfile.png` — Hardened Dockerfile with non-root user
- `05-trivy-scan.png` — ⭐ Security gate showing vulnerability scan
- `07-docker-hub-repo.png` — Public Docker Hub repository

---

### [Stage 3: Kubernetes Manifests + Kustomize](./stage-3-kubernetes/)
✅ **What it proves:** Declarative K8s config management with environment overlays.
- Kustomize base manifests (deployment, service, configmap)
- Dev environment overlay (patches, resource limits)
- Minikube cluster running
- Deployment created and running
- Pod healthy with resource limits and probes
- Service endpoint accessible

**Key files:**
- `03-dev-kustomization.png` — Overlay showing dev-specific patches
- `07-pod-running.png` — Pod status RUNNING
- `10-pod-describe.png` — Security context and resource limits

---

### [Stage 4: Terraform Infrastructure as Code](./stage-4-terraform/)
✅ **What it proves:** Modular, production-grade infrastructure provisioning.
- Terraform module structure (network, security, compute)
- Infrastructure plan with all resources
- AWS VPC created
- AWS Security Groups with proper ingress rules
- EC2 instances (Jenkins master + slave) deployed
- Public IPs and DNS names assigned

**Key files:**
- `04-terraform-plan.png` — Plan showing all resources to be created
- `08-aws-ec2-instances.png` — EC2 console showing running Jenkins instances
- `09-terraform-outputs.png` — Terraform outputs with Jenkins URL

---

### [Stage 5: Ansible Configuration Management](./stage-5-ansible/)
✅ **What it proves:** Automated OS-level configuration and multi-server orchestration.
- Ansible playbook with roles (jenkins-master, jenkins-slave)
- Dynamic EC2 inventory discovery
- Playbook execution with task-by-task output
- SSH verification of installed software
- Jenkins slave registered in Jenkins master

**Key files:**
- `04-playbook-run.png` — Playbook execution showing all tasks succeeding
- `06-jenkins-installed.png` — SSH verification of Jenkins version
- `07-jenkins-slave-registered.png` — Jenkins UI showing registered agent

---

### [Stage 6: Jenkins CI Pipeline](./stage-6-jenkins/) ⭐ SECURITY GATES
✅ **What it proves:** Continuous Integration with integrated security scanning and automated promotion.
- Complete Jenkinsfile with all pipeline stages
- Build #1931 execution proof
- **Trivy security scanning** (CRITICAL severity policy)
- Docker image build and push
- Kubernetes manifest update (GitOps trigger)
- Build completion with SUCCESS status

**Key files:**
- `01-jenkinsfile.png` — Pipeline stages: Checkout → Test → Scan → Build → Push → Update Manifest
- `04-build-tests.png` — Pytest execution showing tests PASSING
- `05-trivy-gate.png` — ⭐ **SECURITY GATE:** Trivy scanning with `--exit-code 1 --severity CRITICAL --ignore-unfixed`
- `08-build-success.png` — Build completion: SUCCESS
- `build-1931-console.log` — Full console output

**Interview talking points:**
- Security gate on every build (Trivy scans before push)
- Automated image promotion to registry
- Manifest update automatically triggers ArgoCD

---

### [Stage 7: ArgoCD GitOps](./stage-7-argocd/)
✅ **What it proves:** Continuous Delivery with GitOps principles and automated deployment orchestration.
- ArgoCD Application CRD managing K8s deployment
- ArgoCD UI dashboard
- Application showing "Synced" status
- Resource hierarchy visualization
- Git repository integration (watches main branch)
- Automatic sync when manifest changes

**Key files:**
- `06-app-status.png` — ArgoCD application status: Synced ✅
- `07-resource-tree.png` — Resource hierarchy: Deployment → Service → Pod
- `10-github-argocd-flow.png` — GitOps flow: GitHub commit → ArgoCD detects → auto-sync

**Interview talking points:**
- Zero-click deployments (manifest changes → auto-deploy)
- Complete audit trail in Git
- Automatic rollback to previous Git state if needed

---

### [Stage 8: Hardening & Defense Readiness](./stage-8-hardening/) ⭐ PRODUCTION READY
✅ **What it proves:** Production-grade security, reliability, and operational readiness.
- Kubernetes security context (non-root user enforcement)
- Pod running as UID 100 (app user, non-root)
- Readiness and liveness probes configured
- Resource requests and limits enforced
- Rollout history and rollback capability demonstrated
- STAGE8-HARDENING-CHECKLIST.md (full validation)
- Fresh Jenkins build Trivy evidence

**Key files:**
- `02-nonroot-pod.png` — Pod running as non-root user (uid=100, gid=100)
- `04-rollback-undo.png` — Rollback executed successfully
- `08-fresh-trivy-gate.png` — ⭐ Fresh authenticated build #1931 Trivy evidence
- `10-final-status.png` — All components healthy and running

**Interview talking points:**
- Defense-in-depth: security from app level to container to orchestration
- Operational resilience: rollback tested and proven
- Compliance-ready: all controls documented and validated

---

## 🎯 For Recruiters: The Complete Story

This project demonstrates:

### **Infrastructure & Cloud (Stage 4)**
- [AWS Resources Created](./stage-4-terraform/08-aws-ec2-instances.png) — Production networking, security groups, multi-instance setup
- Modular Terraform for scalability

### **CI/CD & Security (Stage 6)**
- [Trivy Security Gates](./stage-6-jenkins/05-trivy-gate.png) — Automated vulnerability scanning on every build
- Complete pipeline automation from GitHub to registry

### **Kubernetes & Orchestration (Stage 3, 7, 8)**
- [K8s Deployment with Probes](./stage-3-kubernetes/10-pod-describe.png) — Production-ready configuration
- [ArgoCD GitOps](./stage-7-argocd/06-app-status.png) — Continuous delivery with zero-click deploys
- [Non-root Security Context](./stage-8-hardening/02-nonroot-pod.png) — Defense-in-depth

### **End-to-End Automation (All Stages)**
- GitHub push → Jenkins build → Security scan → Docker push → ArgoCD sync → K8s running

---

## 📊 Statistics

| Metric | Value |
|--------|-------|
| Total Stages | 8 |
| Total Screenshots | 70+ |
| Infrastructure Modules | 3 (network, security, compute) |
| Ansible Roles | 2+ |
| K8s Environments | 2 (base, dev overlay) |
| CI/CD Stages | 5 (checkout, test, scan, build, deploy) |
| Security Gates | 1 (Trivy with CRITICAL policy) |

---

## 🚀 How to Use This Gallery

### For Portfolio
1. Create a GitHub Pages site or portfolio
2. Link to individual stage folders
3. Tell the visual story stage-by-stage

### For Interviews
1. Print the [EVIDENCE-GATHERING-GUIDE.md](./EVIDENCE-GATHERING-GUIDE.md)
2. Walk through each stage screenshot
3. Explain architecture decisions and trade-offs
4. Show: "Here's the security gate," "Here's the rollback," "Here's the GitOps automation"

### For Code Reviews
1. Share specific stage evidence
2. Prove end-to-end functionality
3. Demonstrate security and reliability controls

---

## 📝 Navigation Guide by Topic

### **Security-Focused Recruiter?**
1. [Trivy scan (Docker)](./stage-2-docker/05-trivy-scan.png)
2. [Trivy gate (Jenkins)](./stage-6-jenkins/05-trivy-gate.png)
3. [K8s security context (non-root)](./stage-8-hardening/02-nonroot-pod.png)
4. [RBAC & pod security policy docs](../docs/STAGE8-HARDENING-CHECKLIST.md)

### **Infrastructure-Focused Recruiter?**
1. [Terraform modules](./stage-4-terraform/01-module-structure.png)
2. [AWS resources created](./stage-4-terraform/08-aws-ec2-instances.png)
3. [Ansible automation](./stage-5-ansible/04-playbook-run.png)

### **Kubernetes/Platform Engineer?**
1. [K8s manifests (Kustomize)](./stage-3-kubernetes/03-dev-kustomization.png)
2. [Pod deployment (probes, resources)](./stage-3-kubernetes/10-pod-describe.png)
3. [ArgoCD GitOps](./stage-7-argocd/07-resource-tree.png)
4. [Rollback capability](./stage-8-hardening/04-rollback-undo.png)

### **DevOps/Platform Lead?**
1. [Complete CI/CD pipeline](./stage-6-jenkins/01-jenkinsfile.png)
2. [End-to-end automation](./stage-7-argocd/10-github-argocd-flow.png)
3. [Operational readiness (checklist)](./stage-8-hardening/07-checklist.png)

---

## 📋 Capturing Your Own Evidence

Start with [EVIDENCE-GATHERING-GUIDE.md](./EVIDENCE-GATHERING-GUIDE.md) for detailed instructions on what to screenshot for each stage.

**Quick start:**
```bash
# Each stage has a README with specific items:
cat stage-1-flask-app/README.md  # See what to capture for Stage 1
cat stage-6-jenkins/README.md    # See what to capture for Stage 6
```

---

## ✅ Submission Checklist

Before sharing with recruiters:

- [ ] All 9 stage directories populated with screenshots
- [ ] Key security artifacts visible (Trivy, K8s security context)
- [ ] AWS resources visible in console screenshots
- [ ] Jenkins pipeline showing all stages and security gates
- [ ] ArgoCD syncing manifests automatically
- [ ] K8s deployment healthy and running
- [ ] Command outputs readable (14+ pt font)
- [ ] Consistent file naming (01-, 02-, etc.)
- [ ] README files in each stage directory
- [ ] Commit to GitHub under `images/` folder

---

## 🎓 Interview Prompt Examples

**"Tell me about your most complex DevOps project."**
→ *Open the images folder* → "I built an end-to-end platform that goes from GitHub to production Kubernetes. Here's each stage..." → Walk through stages 0-8 with visual proof.

**"How do you handle security in your pipeline?"**
→ *Show Stage 6 Trivy scan* → "Every build gets scanned for CRITICAL vulnerabilities. Here's the gate blocking images with unfixed CVEs..."

**"Have you rolled back a deployment?"**
→ *Show Stage 8 rollback* → "Yes, this screenshot shows the `kubectl rollout undo` command executing successfully in production..."

**"What's the most impressive part of your project?"**
→ *Show Stage 7 ArgoCD* → "The end-to-end GitOps automation. Push to GitHub → Jenkins builds → image tagged → manifest updated → ArgoCD detects → auto-deploys. Zero-click deployment."

---

## 📞 Questions?

Refer to:
- [EVIDENCE-GATHERING-GUIDE.md](./EVIDENCE-GATHERING-GUIDE.md) — Detailed capture instructions
- [../docs/STAGE8-HARDENING-CHECKLIST.md](../docs/STAGE8-HARDENING-CHECKLIST.md) — Validation checklist
- [../README.md](../README.md) — Main project README

---

**Good luck with your interviews! 🚀**

This visual portfolio speaks volumes about your engineering depth, attention to security, and ability to think end-to-end.
