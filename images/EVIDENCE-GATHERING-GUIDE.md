# 📸 Evidence Gathering Guide — Recruiter-Ready Proof

This guide shows **exactly what to screenshot and capture** for each stage to demonstrate you built a production-ready DevOps platform end-to-end.

**Goal:** Create a visual portfolio that tells the story of your engineering work. Recruiters see it → instantly understand scope + complexity → remember you.

---

## 📋 Quick Checklist (Print this!)

- [ ] Stage 0: Repository structure
- [ ] Stage 1: Flask app running + tests passing
- [ ] Stage 2: Docker image built + security scan
- [ ] Stage 3: Kubernetes deployment running
- [ ] Stage 4: Terraform plan + AWS resources created
- [ ] Stage 5: Ansible playbook execution + EC2 configured
- [ ] Stage 6: Jenkins pipeline success + Trivy gate
- [ ] Stage 7: ArgoCD syncing manifests
- [ ] Stage 8: Full end-to-end flow + security validation

---

## Stage 0: Repository Bootstrap

**What this proves:** You understand DevOps project structure & security best practices.

### Screenshots to capture:
1. **Repository structure in VS Code Explorer**
   - Show the folder tree with all top-level directories
   - Crop: Left sidebar showing `app/`, `docker/`, `kubernetes/`, `terraform/`, `ansible/`, `jenkins/`, `argocd/`, `docs/`
   - File: `stage-0-bootstrap/01-repo-structure.png`

2. **.gitignore file**
   - Open `.gitignore` in editor
   - Show the sensitive file patterns blocked (*.pem, *.key, *.tfstate, .env, *.tfvars)
   - File: `stage-0-bootstrap/02-gitignore.png`

3. **GitHub repo home page**
   - Screenshot your GitHub repo with description and README visible
   - Show: repository name, description, languages, stargazers (if any)
   - File: `stage-0-bootstrap/03-github-repo.png`

4. **README.md displaying**
   - Show the architecture diagram in the README
   - Show the build status table showing all stages
   - File: `stage-0-bootstrap/04-readme-architecture.png`

### Terminal output to capture:
```bash
# Run and screenshot:
tree -L 2 -I '__pycache__|*.pyc|.venv|node_modules' flask-cicd-gitops-platform/
git log --oneline -n 5
git remote -v
```
- File: `stage-0-bootstrap/command-outputs.txt`

---

## Stage 1: Flask Application + Tests

**What this proves:** You can write clean, tested Python code with health checks.

### Screenshots to capture:

1. **Flask app code in VS Code**
   - Show `app/app.py` with `/health` endpoint
   - Highlight: structured routes, error handling
   - File: `stage-1-flask-app/01-app-code.png`

2. **Unit tests in VS Code**
   - Show `app/tests/test_app.py`
   - Highlight: test cases for `/`, `/health`, error scenarios
   - File: `stage-1-flask-app/02-test-code.png`

3. **App running locally**
   - Terminal showing: `python app.py` → `Running on http://127.0.0.1:5000`
   - File: `stage-1-flask-app/03-app-running.png`

4. **Tests passing**
   - Terminal output: `pytest -v` → all tests PASSED
   - Show: test count, pass rate, execution time
   - File: `stage-1-flask-app/04-tests-passing.png`

5. **Live app browser**
   - Browser tab: `http://localhost:5000` → Flask page rendering
   - Browser dev tools: Network tab showing 200 OK
   - File: `stage-1-flask-app/05-browser-response.png`

6. **Health endpoint**
   - Browser or curl: `http://localhost:5000/health` → `{"status": "healthy"}`
   - File: `stage-1-flask-app/06-health-endpoint.png`

### Terminal output to capture:
```bash
# Run and screenshot:
cd app
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
pytest -v --tb=short
python app.py &
curl -s http://localhost:5000/health | jq .
```
- File: `stage-1-flask-app/command-outputs.txt`

---

## Stage 2: Docker Containerization

**What this proves:** You can create secure, non-root container images.

### Screenshots to capture:

1. **Dockerfile in editor**
   - Show `docker/Dockerfile`
   - Highlight: non-root user creation, layer optimization, health check
   - File: `stage-2-docker/01-dockerfile.png`

2. **Image build output**
   - Terminal: `docker build -t emekaezedozie276/flask-app:latest .`
   - Show: successful build, layer caching, final image size
   - File: `stage-2-docker/02-build-success.png`

3. **Image listed locally**
   - Terminal: `docker images | grep flask-app`
   - Show: image ID, size, tag
   - File: `stage-2-docker/03-docker-images.png`

4. **Container running**
   - Terminal: `docker run -p 5000:5000 emekaezedozie276/flask-app:latest`
   - Show: container startup, port mapping, health check
   - File: `stage-2-docker/04-container-running.png`

5. **Trivy security scan**
   - Terminal: `trivy image emekaezedozie276/flask-app:latest`
   - Show: vulnerability scan result, severity breakdown, scan time
   - File: `stage-2-docker/05-trivy-scan.png`

6. **Image pushed to Docker Hub**
   - Terminal: `docker push emekaezedozie276/flask-app:latest`
   - Show: layer digest hashes, successful push
   - File: `stage-2-docker/06-docker-push.png`

7. **Docker Hub registry**
   - Browser: Your Docker Hub profile → flask-app repository
   - Show: image tags, pull count, stars
   - File: `stage-2-docker/07-docker-hub-repo.png`

### Terminal output to capture:
```bash
# Run and screenshot:
docker build -t emekaezedozie276/flask-app:latest docker/
docker images
docker run -p 5000:5000 emekaezedozie276/flask-app:latest &
docker ps
curl http://localhost:5000/health
trivy image emekaezedozie276/flask-app:latest
docker push emekaezedozie276/flask-app:latest
```
- File: `stage-2-docker/command-outputs.txt`

---

## Stage 3: Kubernetes Manifests + Kustomize

**What this proves:** You understand K8s declarative config, overlays, and deployment patterns.

### Screenshots to capture:

1. **Kustomize base directory structure**
   - Show: `kubernetes/base/` with deployment.yaml, service.yaml, configmap.yaml
   - File: `stage-3-kubernetes/01-base-structure.png`

2. **Base deployment.yaml**
   - Show the YAML with probes, resources, image ref
   - Highlight: readinessProbe, livenessProbe, resource requests/limits
   - File: `stage-3-kubernetes/02-deployment-yaml.png`

3. **Dev overlay kustomization.yaml**
   - Show: `kubernetes/overlays/dev/kustomization.yaml`
   - Highlight: patches, image replacement, resource limits
   - File: `stage-3-kubernetes/03-dev-kustomization.png`

4. **Kustomize build output**
   - Terminal: `kubectl kustomize kubernetes/overlays/dev`
   - Show: final manifests with image tag replaced, patches applied
   - File: `stage-3-kubernetes/04-kustomize-build.png`

5. **Minikube cluster info**
   - Terminal: `minikube status`
   - Show: minikube running, kubectl connected
   - File: `stage-3-kubernetes/05-minikube-status.png`

6. **Namespace and deployment created**
   - Terminal: `kubectl get ns,deploy -n flask-app`
   - Show: namespace active, deployment running
   - File: `stage-3-kubernetes/06-namespace-deploy.png`

7. **Pod running**
   - Terminal: `kubectl get pods -n flask-app -o wide`
   - Show: pod name, status RUNNING, IP address
   - File: `stage-3-kubernetes/07-pod-running.png`

8. **Service endpoint**
   - Terminal: `kubectl get svc -n flask-app`
   - Show: service IP, port mapping
   - File: `stage-3-kubernetes/08-service.png`

9. **Health check output**
   - Terminal: `kubectl port-forward -n flask-app svc/flask-app 5000:5000` then `curl http://localhost:5000/health`
   - Show: successful health endpoint
   - File: `stage-3-kubernetes/09-health-check.png`

10. **Pod describe (resources & security context)**
    - Terminal: `kubectl describe pod <pod-name> -n flask-app`
    - Show: resource requests/limits, security context, events
    - File: `stage-3-kubernetes/10-pod-describe.png`

### Terminal output to capture:
```bash
# Run and screenshot:
kubectl kustomize kubernetes/overlays/dev
kubectl apply -k kubernetes/overlays/dev
kubectl get pods -n flask-app
kubectl describe pod -n flask-app <pod-name>
kubectl logs -n flask-app <pod-name>
```
- File: `stage-3-kubernetes/command-outputs.txt`

---

## Stage 4: Terraform Infrastructure

**What this proves:** You can provision cloud infrastructure as code with modularity and best practices.

### Screenshots to capture:

1. **Terraform module structure**
   - Show: `terraform/modules/` with network/, security/, compute/ folders
   - File: `stage-4-terraform/01-module-structure.png`

2. **Terraform variables.tf**
   - Show: `terraform/variables.tf` with documented input variables
   - Highlight: variable descriptions, validation rules
   - File: `stage-4-terraform/02-variables.png`

3. **Terraform main.tf**
   - Show: modular structure calling network, security, compute modules
   - File: `stage-4-terraform/03-main-tf.png`

4. **Terraform plan output**
   - Terminal: `terraform plan -out=tfplan`
   - Show: resources to be created, count, plan summary
   - Crop to show readable portion (resources like VPC, subnet, SG, EC2)
   - File: `stage-4-terraform/04-terraform-plan.png`

5. **Terraform apply output**
   - Terminal: `terraform apply tfplan` (or screenshot the apply output)
   - Show: resources created with IDs
   - File: `stage-4-terraform/05-terraform-apply.png`

6. **AWS Console - VPC**
   - Browser: AWS Console → VPC Dashboard
   - Show: VPC created, subnets, route tables
   - File: `stage-4-terraform/06-aws-vpc.png`

7. **AWS Console - Security Groups**
   - Browser: AWS Console → Security Groups
   - Show: security group with inbound rules (Jenkins, SSH, HTTP)
   - File: `stage-4-terraform/07-aws-security-groups.png`

8. **AWS Console - EC2 Instances**
   - Browser: AWS Console → EC2 Instances
   - Show: Jenkins master and slave instances running
   - Highlight: public IPs, instance types, tags
   - File: `stage-4-terraform/08-aws-ec2-instances.png`

9. **Terraform state output**
   - Terminal: `terraform output`
   - Show: outputs like Jenkins URL, slave IP, VPC ID
   - File: `stage-4-terraform/09-terraform-outputs.png`

### Terminal output to capture:
```bash
# Run and screenshot:
terraform plan -out=tfplan
terraform apply tfplan
terraform output -json
```
- File: `stage-4-terraform/command-outputs.txt`

---

## Stage 5: Ansible Configuration Management

**What this proves:** You can automate OS-level configuration and deployments.

### Screenshots to capture:

1. **Ansible inventory file**
   - Show: `ansible/inventory.ini` with dynamic EC2 inventory reference
   - File: `stage-5-ansible/01-inventory.png`

2. **Ansible playbook**
   - Show: `ansible/site.yml` (main playbook)
   - Highlight: roles, variables, handlers
   - File: `stage-5-ansible/02-playbook.png`

3. **Ansible role structure**
   - Show: `ansible/roles/` with jenkins-master/, jenkins-slave/, etc.
   - File: `stage-5-ansible/03-role-structure.png`

4. **Ansible playbook run output**
   - Terminal: `ansible-playbook -i inventory.ini site.yml -v`
   - Show: task execution, handlers triggered, summary
   - Crop to show readable task names and statuses
   - File: `stage-5-ansible/04-playbook-run.png`

5. **Ansible gather_facts output**
   - Terminal: `ansible all -i inventory.ini -m setup | head -n 100`
   - Show: dynamic inventory working, variables collected
   - File: `stage-5-ansible/05-gather-facts.png`

6. **Jenkins master SSH verification**
   - Terminal: `ssh -i terraform.tfvars ec2-user@<jenkins-master-ip> 'jenkins --version'`
   - Show: Jenkins installed via Ansible
   - File: `stage-5-ansible/06-jenkins-installed.png`

7. **Jenkins slave registered**
   - Browser: Jenkins UI → Manage Nodes → see slave node registered
   - File: `stage-5-ansible/07-jenkins-slave-registered.png`

### Terminal output to capture:
```bash
# Run and screenshot:
ansible-playbook -i ansible/inventory.ini ansible/site.yml -v
ansible all -i ansible/inventory.ini -m ping
ansible all -i ansible/inventory.ini -m setup | head -n 50
```
- File: `stage-5-ansible/command-outputs.txt`

---

## Stage 6: Jenkins CI Pipeline

**What this proves:** You built a complete CI pipeline with security gates.

### Screenshots to capture:

1. **Jenkinsfile in editor**
   - Show: `jenkins/Jenkinsfile` with all pipeline stages
   - Highlight: Build, Test, Scan (Trivy), Push, Update Manifest stages
   - File: `stage-6-jenkins/01-jenkinsfile.png`

2. **Jenkins UI - Job dashboard**
   - Browser: Jenkins → flask-cicd-pipeline job
   - Show: job name, recent builds, build history
   - File: `stage-6-jenkins/02-jenkins-job-dashboard.png`

3. **Jenkins build #1931 - Console output (Checkout)**
   - Browser: Jenkins → flask-cicd-pipeline → Build #1931 → Console
   - Show: git checkout, commit hash
   - File: `stage-6-jenkins/03-build-checkout.png`

4. **Jenkins build #1931 - Test stage**
   - Browser: Console output showing pytest execution
   - Show: test count, pass rate
   - File: `stage-6-jenkins/04-build-tests.png`

5. **Jenkins build #1931 - Trivy scan (SECURITY GATE)**
   - Browser: Console output showing Trivy execution
   - Show: `trivy image --exit-code 1 --severity CRITICAL --ignore-unfixed`
   - Show: Debian packages scanned, python-pkg scanned, result
   - File: `stage-6-jenkins/05-trivy-gate.png`

6. **Jenkins build #1931 - Docker push**
   - Browser: Console output showing docker push
   - Show: successful push, layer digests
   - File: `stage-6-jenkins/06-docker-push.png`

7. **Jenkins build #1931 - Manifest update**
   - Browser: Console output showing image tag replacement
   - Show: git commit message, kubectl manifest update
   - File: `stage-6-jenkins/07-manifest-update.png`

8. **Jenkins build #1931 - Success**
   - Browser: Build page showing "Finished: SUCCESS"
   - Show: build duration, status badge
   - File: `stage-6-jenkins/08-build-success.png`

9. **Jenkins GitHub webhook integration**
   - Browser: Jenkins → flask-cicd-pipeline → Configure
   - Show: GitHub webhook trigger configuration
   - File: `stage-6-jenkins/09-github-webhook.png`

10. **Shared library integration**
    - Show: `jenkins/shared-library/vars/` with scanImage.groovy, pushImage.groovy
    - File: `stage-6-jenkins/10-shared-library.png`

### Terminal output to capture:
```bash
# Download and save console logs:
curl -s -u "admin:${JENKINS_TOKEN}" \
  "http://54.76.201.117:8080/job/flask-cicd-pipeline/1931/consoleText" \
  > stage-6-jenkins/build-1931-console.log
```
- File: `stage-6-jenkins/build-1931-console.log`

---

## Stage 7: ArgoCD GitOps

**What this proves:** You understand continuous delivery, GitOps principles, and automated deployments.

### Screenshots to capture:

1. **ArgoCD Application CRD**
   - Show: `argocd/application.yaml` in editor
   - Highlight: source (Git repo), destination (K8s namespace), sync policy
   - File: `stage-7-argocd/01-application-yaml.png`

2. **ArgoCD install on cluster**
   - Terminal: `kubectl apply -n argocd -f argocd/install.yaml`
   - Show: ArgoCD namespace created
   - File: `stage-7-argocd/02-argocd-install.png`

3. **ArgoCD pods running**
   - Terminal: `kubectl get pods -n argocd`
   - Show: all ArgoCD components running (server, repo-server, controller, etc.)
   - File: `stage-7-argocd/03-argocd-pods.png`

4. **ArgoCD Application created**
   - Terminal: `kubectl get app -n argocd`
   - Show: flask-app-dev app, Synced status
   - File: `stage-7-argocd/04-argocd-app.png`

5. **ArgoCD UI login**
   - Browser: ArgoCD web UI (port-forward to 8080:443)
   - Show: login screen, admin credentials entry
   - File: `stage-7-argocd/05-argocd-login.png`

6. **ArgoCD application dashboard**
   - Browser: ArgoCD → Applications → flask-app-dev
   - Show: application name, sync status (Synced), health status
   - File: `stage-7-argocd/06-app-status.png`

7. **ArgoCD application resources tree**
   - Browser: ArgoCD → App → Resource Tree view
   - Show: deployment, service, pod hierarchy
   - File: `stage-7-argocd/07-resource-tree.png`

8. **ArgoCD sync metrics**
   - Browser: ArgoCD → App → Metrics
   - Show: last sync time, sync duration
   - File: `stage-7-argocd/08-sync-metrics.png`

9. **ArgoCD watching Git repo**
   - Terminal: `kubectl get app -n argocd flask-app-dev -o jsonpath='{.spec.source}'`
   - Show: GitHub repo URL, branch, path being watched
   - File: `stage-7-argocd/09-argocd-git-config.png`

10. **Git manifest commit triggering ArgoCD sync**
    - Browser: GitHub → flask-cicd-gitops-platform → commits
    - Show: recent commit from Jenkins (image tag update)
    - Then show ArgoCD detected it and synced automatically
    - File: `stage-7-argocd/10-github-argocd-flow.png`

### Terminal output to capture:
```bash
# Run and screenshot:
kubectl get app -n argocd
kubectl describe app -n argocd flask-app-dev
kubectl logs -n argocd argocd-application-controller-0 | tail -20
kubectl get pods -n flask-app
```
- File: `stage-7-argocd/command-outputs.txt`

---

## Stage 8: Hardening & Defense Readiness

**What this proves:** You built a production-ready system with security, reliability, and operational playbooks.

### Screenshots to capture:

1. **Kubernetes security context**
   - Terminal: `kubectl get deploy flask-app -n flask-app -o yaml | grep -A 15 securityContext`
   - Show: runAsNonRoot: true, runAsUser: 100, allowPrivilegeEscalation: false
   - File: `stage-8-hardening/01-security-context.png`

2. **Pod running as non-root**
   - Terminal: `kubectl exec -n flask-app <pod> -- id`
   - Show: uid=100(app), gid=100(app) (non-root user)
   - File: `stage-8-hardening/02-nonroot-pod.png`

3. **Rollout history**
   - Terminal: `kubectl rollout history deploy/flask-app -n flask-app`
   - Show: multiple revisions, rollback capability
   - File: `stage-8-hardening/03-rollout-history.png`

4. **Rollback demonstration**
   - Terminal: `kubectl rollout undo deploy/flask-app -n flask-app`
   - Show: deployment rolled back to previous revision
   - File: `stage-8-hardening/04-rollback-undo.png`

5. **Readiness & liveness probes**
   - Terminal: `kubectl get deploy flask-app -n flask-app -o jsonpath='{.spec.template.spec.containers[0].readinessProbe}'`
   - Show: probe configuration (httpGet, initialDelaySeconds, etc.)
   - File: `stage-8-hardening/05-probes.png`

6. **Resource requests and limits**
   - Terminal: `kubectl get deploy flask-app -n flask-app -o yaml | grep -A 10 resources`
   - Show: requests (cpu, memory), limits
   - File: `stage-8-hardening/06-resource-limits.png`

7. **STAGE8-HARDENING-CHECKLIST.md**
   - Show: full checklist document in editor
   - Highlight: all items checked, evidence documented
   - File: `stage-8-hardening/07-checklist.png`

8. **Fresh Jenkins build Trivy evidence**
   - Show: Jenkins console output for build #1931 showing Trivy execution
   - Highlight: Trivy version, severity policy, scan result
   - File: `stage-8-hardening/08-fresh-trivy-gate.png`

9. **End-to-end flow visualization**
   - Screenshot or diagram showing: GitHub → Jenkins → Docker Hub → ArgoCD → K8s → App
   - File: `stage-8-hardening/09-end-to-end-flow.png`

10. **Final deployment status snapshot**
    - Terminal: `kubectl get all -n flask-app`
    - Terminal: `kubectl get app -n argocd`
    - Terminal: `kubectl get pods -n argocd`
    - Show: all components healthy
    - File: `stage-8-hardening/10-final-status.png`

### Terminal output to capture:
```bash
# Run and screenshot:
kubectl get all -n flask-app
kubectl get all -n argocd
kubectl describe deploy flask-app -n flask-app
kubectl rollout status deploy/flask-app -n flask-app
git log --oneline -n 20
```
- File: `stage-8-hardening/command-outputs.txt`

---

## 🎬 How to Take Screenshots Efficiently

### On macOS:
```bash
# Screenshot active window
Shift + Cmd + 4, then Space

# Screenshot full screen
Shift + Cmd + 3

# Screenshot to clipboard (no file)
Cmd + Shift + Ctrl + 3 (then paste into folder)
```

### Better: Use FFmpeg or Asciinema for terminal recordings:
```bash
# Record terminal session (beautiful command output capture)
asciinema rec stage-x-<name>/<output>.cast

# Then convert to GIF for README
```

---

## 📐 Naming Convention

Use this naming for consistency:
```
images/
├── stage-0-bootstrap/
│   ├── 01-repo-structure.png
│   ├── 02-gitignore.png
│   ├── 03-github-repo.png
│   └── command-outputs.txt
├── stage-1-flask-app/
│   ├── 01-app-code.png
│   ├── 02-test-code.png
│   ├── 03-app-running.png
│   ├── 04-tests-passing.png
│   └── ...
├── ... (stage 2-8)
└── README.md (this file)
```

---

## 🎯 Pro Tips for Recruiters

### 1. **Crop your screenshots**
- Don't show entire desktop (messy)
- Show just the terminal window or browser tab
- Make text readable (zoom if needed)

### 2. **Add captions or annotations**
- Use `cmd` + `shift` + `4` then space to mark areas
- Use Preview.app to annotate important details
- Circle the important success indicators

### 3. **Include command outputs as .txt files**
- Copy terminal outputs into text files
- Recruiters can read the full logs without zooming
- Proves the commands actually ran

### 4. **Create a summary INDEX**
- Add `images/INDEX.md` linking to each stage's key evidence
- Example:
  ```markdown
  ## Evidence Index
  
  **Stage 6: Jenkins CI**
  - Build success: [Link to image]
  - Trivy gate passing: [Link to image]
  - Image push: [Link to image]
  ```

### 5. **Tell a visual story**
- Order images chronologically through the pipeline
- Show failures, fixes, and final success
- Recruiters see resilience and debugging skills

---

## 🏁 Final Checklist Before Sharing

- [ ] All 9 stages have at least 8-10 screenshots
- [ ] Security artifacts visible (Trivy scan, K8s security context)
- [ ] AWS resources visible (EC2, VPC, Security Groups)
- [ ] Jenkins console showing security gates
- [ ] ArgoCD UI showing GitOps sync
- [ ] K8s deployment healthy and running
- [ ] All command outputs readable (font size 14+)
- [ ] File naming consistent (01-, 02-, etc.)
- [ ] Add INDEX.md linking to key evidence
- [ ] Commit to GitHub in `images/` folder

---

## 📝 Example: How to Present to Recruiters

```markdown
# Evidence Gallery

I built a complete end-to-end DevOps platform that takes Flask code from GitHub 
to production Kubernetes automatically.

## Pipeline Flow
1. Push code → GitHub webhook
2. Jenkins builds, tests, scans (Trivy), pushes image
3. Jenkins updates K8s manifest
4. ArgoCD detects manifest change → auto-syncs
5. New app version running on K8s

## Key Evidence

### Security Gates
- [Trivy Scan Results](images/stage-6-jenkins/05-trivy-gate.png)
- [K8s Non-Root Enforcement](images/stage-8-hardening/02-nonroot-pod.png)

### Infrastructure as Code
- [Terraform Plan](images/stage-4-terraform/04-terraform-plan.png)
- [AWS Resources Created](images/stage-4-terraform/08-aws-ec2-instances.png)

### GitOps & Deployment
- [ArgoCD App Syncing](images/stage-7-argocd/07-resource-tree.png)
- [Rollback Capability](images/stage-8-hardening/04-rollback-undo.png)

...
```

---

## 🚀 Ready to Capture?

Start with **Stage 1 (Flask app + tests)** — it's the easiest to demonstrate locally, then work your way through to Stage 8 for maximum impact.

**Next:** Check each stage subfolder in `/images` for the specific items to capture!
