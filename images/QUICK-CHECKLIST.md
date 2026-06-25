# 🎯 Quick Evidence Capture Checklist

Print this and use it as a checklist while taking screenshots. ✅ Check off items as you capture them.

---

## Stage 1: Flask App (20 min) ⭐ START HERE

**Why:** Easiest to demonstrate locally, builds confidence.

```bash
# Terminal commands to run
cd app && source .venv/bin/activate
python app.py &
pytest -v
curl http://localhost:5000/health
```

**Screenshots needed:**
- [ ] `01-app-code.png` — app.py showing routes
- [ ] `02-test-code.png` — test_app.py with test cases
- [ ] `03-app-running.png` — "Running on http://127.0.0.1:5000"
- [ ] `04-tests-passing.png` — pytest output: ✓ all tests passed
- [ ] `06-health-endpoint.png` — curl showing `{"status": "healthy"}`

**Browser screenshot:**
- [ ] `05-browser-response.png` — localhost:5000 in browser

---

## Stage 2: Docker (15 min) ⭐ SECURITY PROOF

**Why:** Shows container security knowledge. Trivy scan is key recruiter evidence.

```bash
cd docker
docker build -t emekaezedozie276/flask-app:latest .
docker images
docker run -p 5000:5000 emekaezedozie276/flask-app:latest &
trivy image emekaezedozie276/flask-app:latest | head -n 50
docker push emekaezedozie276/flask-app:latest
```

**Screenshots needed:**
- [ ] `01-dockerfile.png` — Dockerfile in VS Code
- [ ] `02-build-success.png` — Successful build output
- [ ] `03-docker-images.png` — `docker images` showing flask-app
- [ ] `04-container-running.png` — Container starting output
- [ ] `05-trivy-scan.png` — ⭐ Trivy scan showing vulnerabilities
- [ ] `06-docker-push.png` — Successful push with layer hashes
- [ ] `07-docker-hub-repo.png` — Docker Hub registry page

---

## Stage 3: Kubernetes (20 min)

**Why:** Proves K8s knowledge. Overlays and probes matter.

```bash
kubectl kustomize kubernetes/overlays/dev | head -n 100
kubectl apply -k kubernetes/overlays/dev
kubectl get pods -n flask-app
kubectl describe pod -n flask-app <pod-name>
kubectl port-forward -n flask-app svc/flask-app 5000:5000 &
curl http://localhost:5000/health
```

**Screenshots needed:**
- [ ] `03-dev-kustomization.png` — kustomization.yaml showing patches
- [ ] `05-minikube-status.png` — `minikube status` showing cluster running
- [ ] `07-pod-running.png` — `kubectl get pods` showing RUNNING
- [ ] `10-pod-describe.png` — `kubectl describe pod` showing resources and security

---

## Stage 4: Terraform (15 min)

**Why:** Infrastructure as Code proof. Show modular approach.

```bash
cd terraform/environments/dev
terraform plan -out=tfplan
terraform apply tfplan
terraform output -json | jq .
```

**Screenshots needed:**
- [ ] `04-terraform-plan.png` — Resources to be created
- [ ] `05-terraform-apply.png` — Resources created
- [ ] `08-aws-ec2-instances.png` — AWS EC2 console showing instances
- [ ] `09-terraform-outputs.png` — `terraform output` with IPs/URLs

**Browser screenshot:**
- [ ] `06-aws-vpc.png` — AWS VPC Dashboard
- [ ] `07-aws-security-groups.png` — AWS Security Groups

---

## Stage 5: Ansible (10 min)

**Why:** Configuration automation at scale.

```bash
cd ansible
ansible-playbook -i inventory.ini site.yml -v | head -n 200
ansible all -i inventory.ini -m ping
ssh ec2-user@<jenkins-ip> 'jenkins --version'
```

**Screenshots needed:**
- [ ] `04-playbook-run.png` — Playbook execution with tasks
- [ ] `06-jenkins-installed.png` — SSH verification of Jenkins

**Browser screenshot:**
- [ ] `07-jenkins-slave-registered.png` — Jenkins UI showing slave node

---

## Stage 6: Jenkins ⭐⭐⭐ MOST IMPORTANT

**Why:** The complete CI pipeline. Security gates are critical.

**Jenkins URL:** http://54.76.201.117:8080

**Steps:**
1. Log in (admin account)
2. Go to flask-cicd-pipeline job
3. Click on latest successful build (e.g., #1931)
4. Look at Console Output and screenshot each stage

```bash
# Optional: download console log
curl -s -u "admin:${JENKINS_TOKEN}" \
  "http://54.76.201.117:8080/job/flask-cicd-pipeline/1931/consoleText" \
  > jenkins-console-1931.log
```

**Screenshots needed:**
- [ ] `01-jenkinsfile.png` — Jenkinsfile showing stages
- [ ] `02-jenkins-job-dashboard.png` — Job home page
- [ ] `03-build-checkout.png` — Console: checkout stage
- [ ] `04-build-tests.png` — Console: test stage (pytest output)
- [ ] `05-trivy-gate.png` — ⭐⭐⭐ **Console: Trivy scan** (MOST IMPORTANT)
  - Look for: `trivy image --exit-code 1 --severity CRITICAL --ignore-unfixed`
  - Crop to show the full command and results
- [ ] `06-docker-push.png` — Console: docker push output
- [ ] `07-manifest-update.png` — Console: git commit for image tag update
- [ ] `08-build-success.png` — "Finished: SUCCESS"
- [ ] `build-1931-console.log` — Full console text file

---

## Stage 7: ArgoCD ⭐ GITOPS FLOW

**Why:** The delivery automation. Shows Git → Deploy flow.

**ArgoCD URL:** kubectl port-forward -n argocd svc/argocd-server 8080:443 (then https://localhost:8080)

**Username:** admin
**Password:** kubectl get secret -n argocd argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d

```bash
kubectl get app -n argocd
kubectl describe app -n argocd flask-app-dev
kubectl get pods -n argocd
```

**Screenshots needed:**
- [ ] `06-app-status.png` — ArgoCD UI showing "Synced" status
- [ ] `07-resource-tree.png` — Resource tree: Deployment → Service → Pod
- [ ] `03-argocd-pods.png` — `kubectl get pods -n argocd` showing all running

**Browser screenshots:**
- [ ] `05-argocd-login.png` — ArgoCD login page
- [ ] `10-github-argocd-flow.png` — Show: GitHub commit → ArgoCD synced

---

## Stage 8: Hardening ⭐ PRODUCTION READY

**Why:** Security, reliability, and operational maturity.

```bash
kubectl -n flask-app get deploy flask-app -o yaml | grep -A 20 securityContext
kubectl exec -n flask-app <pod> -- id
kubectl rollout history deploy/flask-app -n flask-app
kubectl rollout undo deploy/flask-app -n flask-app
kubectl get all -n flask-app
```

**Screenshots needed:**
- [ ] `02-nonroot-pod.png` — `kubectl exec -- id` showing uid=100
- [ ] `04-rollback-undo.png` — Rollback command executed
- [ ] `08-fresh-trivy-gate.png` — ⭐ Jenkins build #1931 Trivy evidence
- [ ] `10-final-status.png` — `kubectl get all` showing healthy system

**VS Code screenshots:**
- [ ] `07-checklist.png` — docs/STAGE8-HARDENING-CHECKLIST.md

---

## 📊 Priority Matrix

**Must Have (Do These First):**
- ✅ Stage 1: Tests passing
- ✅ Stage 2: Trivy scan
- ✅ Stage 6: Jenkins Trivy gate
- ✅ Stage 8: Fresh build evidence + security context

**Important (Do These Second):**
- ✅ Stage 3: K8s running with probes
- ✅ Stage 7: ArgoCD GitOps flow
- ✅ Stage 4: AWS resources
- ✅ Stage 5: Ansible execution

**Nice to Have (Polish):**
- ✅ Stage 0: Repository structure
- ✅ All terminal outputs as text files
- ✅ Annotations on screenshots

---

## 🎬 Screenshot Tips

### macOS Shortcuts
```
Shift + Cmd + 4 + Space    → Screenshot window (best for code)
Shift + Cmd + 3            → Screenshot full screen
Shift + Cmd + Ctrl + 3     → Screenshot to clipboard
```

### Best Practices
1. **Close other windows** — Clean desktop, no clutter
2. **Zoom UI if needed** — Make text readable (at least 12pt)
3. **Crop to essentials** — Show just the relevant part
4. **Include terminal prompt** — Proves you ran commands

### Tools
- **Preview.app** — Quick annotations with circles/arrows
- **Markup** — Built-in macOS tool (press Shift+Cmd+A in Preview)
- **Asciinema** — Record terminal sessions as GIFs

---

## 📁 File Naming Convention

```
images/
├── stage-0-bootstrap/
│   ├── README.md
│   ├── 01-repo-structure.png
│   ├── 02-gitignore.png
│   └── command-outputs.txt
├── stage-1-flask-app/
│   ├── README.md
│   ├── 01-app-code.png
│   ├── 02-test-code.png
│   ├── 03-app-running.png
│   ├── 04-tests-passing.png
│   ├── 05-browser-response.png
│   ├── 06-health-endpoint.png
│   └── command-outputs.txt
├── ...
└── INDEX.md (master index)
```

**Pattern:** `NN-description.png` (numbers ensure proper ordering)

---

## ⏱️ Total Time Estimate

- Stage 1: 20 min
- Stage 2: 15 min
- Stage 3: 20 min
- Stage 4: 15 min
- Stage 5: 10 min
- Stage 6: 30 min ⭐ (Trivy proof is critical)
- Stage 7: 15 min
- Stage 8: 20 min
- **Total: ~2.5 hours for complete gallery**

---

## ✅ Final Checklist Before Submitting to Recruiters

- [ ] All 9 stages have screenshots
- [ ] Jenkins Trivy scan visible and clear (Stage 6)
- [ ] K8s security context visible (Stage 8)
- [ ] ArgoCD Synced status visible (Stage 7)
- [ ] All command outputs readable (14+ pt)
- [ ] File names consistent (01-, 02-, etc.)
- [ ] README in each stage directory
- [ ] INDEX.md complete with navigation
- [ ] Committed to GitHub in `images/` folder
- [ ] Links in main README pointing to images/

---

## 🚀 You're Ready!

This visual evidence tells your story better than any resume. Start with Stage 1 today. ⭐
