# Stage 6 — Jenkins CI Pipeline

> Everything an engineer needs to understand, configure, defend, and troubleshoot the Jenkins CI implementation in this project — written to serve both day-to-day operations and interview-level depth.

---

## Table of Contents

1. [Why Jenkins?](#1-why-jenkins)
2. [Architecture — Master / Slave Topology](#2-architecture--master--slave-topology)
3. [Folder Structure Explained](#3-folder-structure-explained)
4. [The CI Pipeline — Stage by Stage](#4-the-ci-pipeline--stage-by-stage)
5. [Declarative Pipeline Concepts](#5-declarative-pipeline-concepts)
6. [Shared Library — Design and Implementation](#6-shared-library--design-and-implementation)
7. [Each Shared Library Step Explained](#7-each-shared-library-step-explained)
8. [Credentials Management](#8-credentials-management)
9. [Jenkins Setup Checklist](#9-jenkins-setup-checklist)
10. [Security Hardening](#10-security-hardening)
11. [GitOps Integration — How Jenkins Triggers ArgoCD](#11-gitops-integration--how-jenkins-triggers-argocd)
12. [Key Jenkins Concepts for Interviews](#12-key-jenkins-concepts-for-interviews)
13. [Troubleshooting Reference](#13-troubleshooting-reference)

---

## 1. Why Jenkins?

Jenkins is an open-source automation server that orchestrates the CI (Continuous Integration) half of the pipeline. It was chosen here because:

| Requirement | How Jenkins addresses it |
|---|---|
| Source-controlled pipeline | `Jenkinsfile` lives in the repo alongside the code — infrastructure and pipeline are versioned together |
| Reusable logic | Shared library pattern eliminates copy-paste across projects |
| Extensible | 1,800+ plugins cover any integration (GitHub, Docker, Trivy, Slack) |
| Master/slave architecture | Builds run on dedicated slave agents, keeping the master lightweight and stable |
| Self-hosted control | No SaaS dependency; pipeline data stays within the VPC |

**Alternative tools considered:**

| Tool | Why not chosen here |
|---|---|
| GitHub Actions | Good but tightly coupled to GitHub SaaS; harder to run in fully private VPC |
| GitLab CI | Excellent but requires GitLab as the SCM host |
| CircleCI / Travis | SaaS-only options; cost and data residency concerns |

---

## 2. Architecture — Master / Slave Topology

```
                    GitHub
                      │
                  (webhook push)
                      │
                      ▼
          ┌─────────────────────┐
          │   Jenkins Master    │   Public Subnet — eu-west-1a
          │   54.76.201.117     │   Port 8080 (UI + API)
          │   t3.medium         │
          └─────────┬───────────┘
                    │
               (JNLP :50000)
               (SSH  :22)
                    │
          ┌─────────▼───────────┐
          │   Jenkins Slave     │   Private Subnet — eu-west-1b
          │   10.0.10.129       │   No public IP
          │   t3.medium         │
          │   label: "slave"    │
          └─────────────────────┘
                    │
          (docker build, trivy scan, docker push, git push)
```

### Why separate master and slave?

**Master responsibilities:**
- Store configuration, build history, credentials, and plugin state
- Schedule jobs and dispatch them to available slaves
- Serve the web UI and REST API
- Never run actual build workloads

**Slave responsibilities:**
- Execute all pipeline stages in an isolated workspace
- Run Docker builds (requires Docker daemon)
- Run Trivy scans (requires internet egress via NAT)
- Push to Docker Hub (requires internet egress via NAT)

**Why this matters operationally:**
- If a build corrupts the workspace or crashes a process, the master is unaffected
- Multiple slaves can be added horizontally to parallelize builds
- The slave has no public IP — all internet egress goes through the NAT Gateway; inbound internet access to the slave is impossible

---

## 3. Folder Structure Explained

```
jenkins/
├── Jenkinsfile                         # Main pipeline definition
└── shared-library/
    ├── vars/                           # Global pipeline steps (auto-loaded by @Library)
    │   ├── buildImage.groovy           # docker build
    │   ├── scanImage.groovy            # trivy image scan
    │   ├── pushImage.groovy            # docker push
    │   ├── updateManifest.groovy       # sed image tag in K8s overlay
    │   └── pushManifest.groovy         # git commit + push to trigger ArgoCD
    └── src/                            # Optional Groovy class helpers (empty for now)
```

**Why the `vars/` convention?**

Jenkins shared library `vars/` files define **global pipeline variables** — functions that can be called directly by name in any Jenkinsfile that loads the library. Each `.groovy` file in `vars/` must contain a `def call(...)` method. When Jenkins sees `buildImage(...)` in a Jenkinsfile, it resolves it to `vars/buildImage.groovy:call(...)` automatically.

---

## 4. The CI Pipeline — Stage by Stage

```
GitHub push
    │
    ▼
[1] Checkout ──► clone repo, log last commit
    │
    ▼
[2] Test ──────► python -m pytest  (fails here = no image built)
    │
    ▼
[3] Build ─────► docker build -t emekaezedozie276/flask-app:BUILD_NUMBER
    │
    ▼
[4] Scan ──────► trivy image --severity CRITICAL  (fails here = no push)
    │
    ▼
[5] Push ──────► docker push to Docker Hub
    │
    ▼
[6] Update ────► sed replaces image tag in kubernetes/overlays/dev/deployment-patch.yaml
    │
    ▼
[7] Publish ───► git commit + git push to main  ◄─── ArgoCD detects this
    │
    ▼
ArgoCD syncs → Kubernetes rolls out new image
```

**The security gate principle:**

Every stage is a quality gate. A failure at any stage stops the pipeline and prevents a broken or vulnerable image from reaching the registry or the cluster:

- Tests fail → no image built
- Trivy finds a CRITICAL CVE → image built locally but never pushed
- Git push fails → image is in Docker Hub but manifest is not updated, so ArgoCD will not deploy it

---

## 5. Declarative Pipeline Concepts

### `@Library('flask-cicd-shared-library') _`

This loads the shared library registered in Jenkins under the name `flask-cicd-shared-library`. The trailing `_` is required Groovy syntax when loading a library without importing specific classes from it.

```groovy
@Library('flask-cicd-shared-library') _
```

### `agent { label 'slave' }`

Routes all stages to the Jenkins node that has the label `slave`. This ensures builds run on the dedicated slave EC2 (10.0.10.129), not the master.

### `environment { ... }`

Defines pipeline-scoped environment variables accessible in any stage as `env.VARIABLE_NAME`. Centralising them here means changing the Docker image name or Dockerfile path requires editing one block, not hunting through stages.

### `options { ... }`

```groovy
options {
    buildDiscarder(logRotator(numToKeepStr: '10'))  // Keep only last 10 builds
    disableConcurrentBuilds()                        // No parallel runs of this pipeline
    timeout(time: 30, unit: 'MINUTES')               // Kill runaway builds after 30 min
}
```

`disableConcurrentBuilds()` is critical for the manifest-update pattern. If two builds run simultaneously, they both try to push a `git commit` to the same file in the same branch — this causes a race condition and one push will fail or overwrite the other.

### `triggers { githubPush() }`

Activates the GitHub push webhook trigger. When any commit lands on the tracked branch, GitHub sends an HTTP POST to `http://54.76.201.117:8080/github-webhook/` and Jenkins starts the pipeline automatically.

### `post { ... }`

Runs after all stages regardless of success or failure:
- `success`: log the promoted image reference
- `failure`: log the stage that failed
- `always`: `cleanWs()` deletes the slave workspace — prevents disk fill-up from accumulated build artifacts

---

## 6. Shared Library — Design and Implementation

### What is a Jenkins Shared Library?

A shared library is a Git repository (or a folder within one) that contains reusable Groovy code. Multiple Jenkinsfiles across multiple projects can load it with `@Library`, eliminating code duplication.

### How Jenkins resolves it

1. Engineer registers the library in **Manage Jenkins → Configure System → Global Pipeline Libraries**:
   - Name: `flask-cicd-shared-library`
   - Source: SCM → Git → `https://github.com/Ike-DevCloudIQ/flask-cicd-gitops-platform.git`
   - Library path: `jenkins/shared-library`
   - Default version: `main`
2. At runtime, Jenkins checks out the library from Git
3. Files in `vars/` are imported as global functions
4. `@Library('flask-cicd-shared-library') _` in the Jenkinsfile triggers this resolution

### The `def call(...)` convention

Every file in `vars/` must expose a `call()` method. This is what makes `buildImage(...)` work as if it were a built-in Jenkins step:

```groovy
// vars/buildImage.groovy
def call(String imageName, String buildNum, String dockerfile = 'docker/Dockerfile') {
    sh "docker build -t ${imageName}:${buildNum} -f ${dockerfile} ."
}
```

When Jenkins sees `buildImage(env.DOCKER_IMAGE, env.BUILD_NUMBER, env.DOCKERFILE_PATH)` in the Jenkinsfile, it calls `buildImage.call(...)`.

---

## 7. Each Shared Library Step Explained

### buildImage.groovy

**What it does**: Runs `docker build` and tags the image with the Jenkins `BUILD_NUMBER`.

**Why `BUILD_NUMBER` not `latest`?**

The `latest` tag is an anti-pattern in CI/CD:
- It is mutable — `latest` today is not the same image as `latest` tomorrow
- You cannot roll back to a specific version by tag
- Kubernetes image pull policy `IfNotPresent` with `latest` causes unpredictable behaviour

`BUILD_NUMBER` (e.g., `42`) is immutable, traceable, and monotonically increasing. If build 44 is broken, you can roll back to tag `43` exactly.

```groovy
def call(String imageName, String buildNum, String dockerfile = 'docker/Dockerfile') {
    sh "docker build -t ${imageName}:${buildNum} -f ${dockerfile} ."
}
```

---

### scanImage.groovy

**What it does**: Runs Trivy against the locally built image and fails the pipeline if any `CRITICAL` severity CVE is found.

**Why scan before push?**

If you push first and scan second, a vulnerable image lands in your registry and potentially in your cluster before anyone can react. Scanning in the pipeline, between build and push, ensures **only approved images leave the build environment**.

```
trivy image \
  --exit-code 1 \          # Non-zero exit = pipeline fails
  --severity CRITICAL \    # Only break for CRITICAL (not HIGH/MEDIUM)
  --output trivy-report.txt \
  imageName:tag
```

The report is archived with `archiveArtifacts` so it is available in the Jenkins build history for audit purposes even after the workspace is cleaned.

**Severity levels in Trivy** (low → high):
`UNKNOWN < LOW < MEDIUM < HIGH < CRITICAL`

---

### pushImage.groovy

**What it does**: Authenticates to Docker Hub and pushes the scanned image.

**Why `withCredentials` instead of environment variables?**

```groovy
withCredentials([usernamePassword(
    credentialsId: 'dockerhub-credentials',
    usernameVariable: 'DOCKER_USER',
    passwordVariable: 'DOCKER_PASS'
)]) { ... }
```

- Credentials stored in the Jenkins credential store are encrypted at rest
- `withCredentials` masks the values in all console output — they appear as `****` in logs
- The credentials are only in memory for the duration of the block
- No credentials ever appear in the Jenkinsfile itself

**`--password-stdin` vs `-p password`**: piping the password avoids it appearing in the process list (`ps aux`), which could expose it to other users on the same host.

---

### updateManifest.groovy

**What it does**: Updates the image tag in the Kustomize overlay deployment patch using `sed`.

```groovy
sh "sed -i 's|image: ${imageName}:.*|image: ${imageName}:${buildNum}|g' ${patchFile}"
```

**The file it modifies**: `kubernetes/overlays/dev/deployment-patch.yaml`

**Why `sed` and not a YAML parser?**

On a fresh Jenkins slave, no YAML parser is guaranteed to be installed. `sed` is universally available on Linux and reliably replaces the single image tag line. The `|` delimiter instead of `/` avoids conflicts with forward slashes in the image name.

**What the change looks like in Git:**

```diff
- image: emekaezedozie276/flask-app:41
+ image: emekaezedozie276/flask-app:42
```

---

### pushManifest.groovy

**What it does**: Commits the modified manifest and pushes it to `main`, completing the GitOps loop.

```groovy
git config user.email "jenkins@flask-cicd-gitops-platform"
git config user.name  "Jenkins CI"
git add kubernetes/overlays/dev/deployment-patch.yaml
git diff --cached --quiet || git commit -m "ci: update image tag to build-${buildNum} [skip ci]"
git push https://${GIT_USER}:${GIT_TOKEN}@github.com/...
```

**Key design decisions:**

1. **`git diff --cached --quiet || git commit`** — if the image tag did not change (e.g., pipeline re-run without a code change), there is nothing to commit. This guard prevents `git commit` from failing when the working tree is clean.

2. **`[skip ci]` in the commit message** — conventional marker that tells CI systems to skip triggering a new build from this commit. Without it, Jenkins would trigger itself in an infinite loop: code push → Jenkins builds → Jenkins pushes manifest → triggers Jenkins → builds again.

3. **Credentials in the push URL** — Git credentials are injected into the remote URL via `withCredentials` so they are masked in logs. The actual push URL in logs shows as `https://****:****@github.com/...`.

4. **`HEAD:main`** — pushes the current HEAD to the `main` branch explicitly, regardless of what branch the workspace was checked out from.

---

## 8. Credentials Management

Jenkins stores credentials encrypted in `$JENKINS_HOME/credentials.xml`. They are never stored in plaintext and are masked in all console output.

### Required credentials for this pipeline

| Credential ID | Type | Used in | Where to get it |
|---|---|---|---|
| `dockerhub-credentials` | Username with password | `pushImage.groovy` | Docker Hub → Account Settings → Security → New Access Token |
| `github-credentials` | Username with password | `pushManifest.groovy` | GitHub → Settings → Developer Settings → Personal Access Tokens → Classic → repo scope |

### How to add credentials in Jenkins UI

1. Go to `http://54.76.201.117:8080`
2. Navigate: **Manage Jenkins → Credentials → System → Global credentials**
3. Click **Add Credentials**
4. Kind: `Username with password`
5. Set the exact ID matching the value in the Groovy files (`dockerhub-credentials` or `github-credentials`)
6. Username: Docker Hub / GitHub username
7. Password: Access token (not your account password)

### Why use access tokens instead of account passwords?

- Tokens have limited scope (e.g., GitHub PAT with only `repo` permission cannot delete your account)
- Tokens can be revoked individually without changing your account password
- Docker Hub access tokens support read-only or read/write scopes — use read/write for CI push
- OWASP recommends least-privilege credentials at all integration points

---

## 9. Jenkins Setup Checklist

Complete these steps in the Jenkins UI before running the pipeline.

### Step 1 — Unlock Jenkins

Open `http://54.76.201.117:8080` and enter the initial admin password:

```bash
ssh -i ~/.ssh/flask-cicd-gitops-dev-key.pem ec2-user@54.76.201.117 \
    'sudo cat /var/lib/jenkins/secrets/initialAdminPassword'
```

### Step 2 — Install suggested plugins

When prompted, select "Install suggested plugins". This installs Git, GitHub, Pipeline, Credentials Binding, and other essentials.

### Step 3 — Create admin user

Replace the default admin with a named user and strong password.

### Step 4 — Install additional plugins

Navigate to **Manage Jenkins → Plugins → Available plugins** and install:

| Plugin | Purpose |
|---|---|
| Docker Pipeline | `docker.build()`, `docker.withRegistry()` helpers |
| GitHub Integration | Webhook-based push triggers (`githubPush()`) |
| Credentials Binding | `withCredentials([usernamePassword(...)])` |
| Blue Ocean (optional) | Visual pipeline UI |

### Step 5 — Configure the shared library

1. Go to **Manage Jenkins → Configure System**
2. Scroll to **Global Pipeline Libraries**
3. Click **Add**:
   - Name: `flask-cicd-shared-library`
   - Default version: `main`
   - Retrieval method: Modern SCM → Git
   - Repository URL: `https://github.com/Ike-DevCloudIQ/flask-cicd-gitops-platform.git`
   - Library path: `jenkins/shared-library`
4. Save

### Step 6 — Add credentials

Add `dockerhub-credentials` and `github-credentials` as described in section 8.

### Step 7 — Configure slave node

1. Go to **Manage Jenkins → Manage Nodes → New Node**
2. Name: any (e.g., `jenkins-slave`)
3. Type: Permanent Agent
4. Remote root directory: `/opt/jenkins-agent`
5. Labels: `slave`
6. Launch method: Launch agents via SSH
7. Host: `10.0.10.129`
8. Credentials: Add a new SSH private key credential using `~/.ssh/flask-cicd-gitops-dev-key.pem`
9. Host Key Verification Strategy: Non-verifying (or Known hosts file)

### Step 8 — Create the pipeline job

1. **New Item → Pipeline**
2. Name: `flask-cicd-pipeline`
3. Under **Build Triggers**: check `GitHub hook trigger for GITScm polling`
4. Under **Pipeline**: select `Pipeline script from SCM`
5. SCM: Git
6. Repository URL: `https://github.com/Ike-DevCloudIQ/flask-cicd-gitops-platform.git`
7. Credentials: `github-credentials`
8. Script Path: `jenkins/Jenkinsfile`
9. Save and run **Build Now** to validate

### Step 9 — Configure GitHub webhook

In GitHub repository → **Settings → Webhooks → Add webhook**:
- Payload URL: `http://54.76.201.117:8080/github-webhook/`
- Content type: `application/json`
- Trigger: `Just the push event`

---

## 10. Security Hardening

### Pipeline-level hardening already implemented

| Practice | Implementation |
|---|---|
| No `latest` tags | All images tagged with `BUILD_NUMBER` |
| Secrets masked in logs | All credentials use `withCredentials` |
| Credential store | Jenkins encrypted credential store, never in Jenkinsfile |
| Scan before push | Trivy runs between build and push — vulnerable images cannot reach the registry |
| Slave isolation | Builds run on private-subnet slave, not on master |
| Concurrent build lock | `disableConcurrentBuilds()` prevents race conditions on manifest updates |
| Workspace cleanup | `cleanWs()` in `post { always }` removes all build artefacts after each run |
| `[skip ci]` guard | Prevents infinite loop from manifest-update commits |

### Recommended additional hardening

| Practice | Why |
|---|---|
| Enable Jenkins CSRF protection | Prevents cross-site request forgery attacks on the Jenkins API |
| Restrict `jenkins` user sudoers | Jenkins process should only need to run `docker` commands |
| Rotate Jenkins admin password | Default password from `initialAdminPassword` should be changed immediately |
| Use Docker Hub access token, not password | Token is scoped and revocable |
| Use GitHub PAT with minimum scope | `repo` scope only — no admin, no delete |
| Enable Jenkins audit log | Tracks who triggered what and when |
| Enable HTTPS on Jenkins | Use an ALB with ACM certificate in front of Jenkins port 8080 for production |

---

## 11. GitOps Integration — How Jenkins Triggers ArgoCD

This is the complete pipeline loop from code push to live deployment:

```
Developer pushes code to main
         │
         ▼
GitHub webhook fires → Jenkins master receives POST
         │
         ▼
Jenkins dispatches job to slave (label: slave)
         │
         ▼
Stages: Checkout → Test → Build → Scan → Push → Update Manifest → Publish Manifest
         │                                                             │
         │                                             git push to main
         │                                                             │
         ▼                                                             ▼
Docker Hub receives                                 ArgoCD polls main every 3 minutes
new image emekaezedozie276/flask-app:BUILD_NUMBER   OR receives webhook → detects
                                                    manifest change in
                                                    kubernetes/overlays/dev/deployment-patch.yaml
                                                                       │
                                                                       ▼
                                                    ArgoCD runs kubectl apply
                                                    Kubernetes rolls out new Deployment
                                                    Old pods replaced with new image
```

**Why Jenkins does not deploy directly to Kubernetes:**

Giving Jenkins `kubectl` access and having it apply manifests directly would work but violates GitOps principles:
- The cluster state would not be traceable from Git
- A network partition could cause Jenkins and the cluster to diverge silently
- Rollback would require re-running a Jenkins build, not a `git revert`

Instead, Jenkins only updates Git. ArgoCD is the single actor that applies manifests to the cluster. Git is always the source of truth.

---

## 12. Key Jenkins Concepts for Interviews

### What is a Jenkins Shared Library?

A Git repository (or subfolder) containing reusable Groovy code. It is registered in Jenkins and loaded into any Jenkinsfile with `@Library('name')`. Files in `vars/` are available as global pipeline steps. This promotes DRY (Don't Repeat Yourself) across multiple pipelines.

### Declarative vs Scripted Pipeline — what is the difference?

| Aspect | Declarative | Scripted |
|---|---|---|
| Syntax | Structured, opinionated (`pipeline { }` block) | Groovy code, full flexibility |
| Error handling | Built-in `post` block | Manual try/catch |
| Learning curve | Easier for teams | Requires Groovy knowledge |
| Use case | Standard CI/CD pipelines | Complex conditional logic |
| This project | Uses Declarative | — |

### What does `agent { label 'slave' }` do?

Routes pipeline execution to any Jenkins node with the label `slave`. Jenkins polls available nodes and assigns the build to a matching idle one. If no matching node is available, the build queues until one becomes free.

### What is `withCredentials` and why use it?

A Jenkins Pipeline DSL step that securely injects credentials into a block scope. Values are automatically masked (`****`) in all console output. The credentials are fetched from Jenkins' encrypted credential store at runtime and are only held in memory for the block's duration.

### How do you prevent a pipeline from running twice simultaneously?

`disableConcurrentBuilds()` in the `options` block. This is critical when a pipeline modifies shared state such as a Git repository or a deployment manifest.

### What is the purpose of `cleanWs()` in `post { always }`?

Deletes the entire build workspace on the slave after each run. This prevents:
- Disk fill-up from accumulated Docker image layers, test outputs, and scan reports
- Stale files from a previous build affecting the next one
- Sensitive data (build outputs, downloaded secrets) remaining on disk

### How does Jenkins know when to start a build?

In this project, via a **GitHub webhook**. When a commit is pushed to the repo, GitHub sends an HTTP POST to `http://master:8080/github-webhook/`. Jenkins receives it, resolves the matching pipeline job, and queues a build. The `githubPush()` trigger in the Jenkinsfile opts in to this behaviour.

### What is `[skip ci]` in a commit message?

A conventional string that CI systems recognise as a signal to not trigger a build from that commit. Used in the manifest-update commit to break the feedback loop: without it, Jenkins would see its own git push as a new commit and trigger itself indefinitely.

### What is the difference between `BUILD_NUMBER` and `GIT_COMMIT` as an image tag?

| Tag type | Format | Advantages | Disadvantages |
|---|---|---|---|
| `BUILD_NUMBER` | `42` | Short, sequential, easy to correlate with Jenkins build | Not directly traceable to a Git commit |
| `GIT_COMMIT` | `a3f2e1b` | Directly links image to exact source code | Long, harder to compare ordering |
| Both combined | `42-a3f2e1b` | Best of both worlds | Slightly longer |

This project uses `BUILD_NUMBER` for simplicity. In production, combining both is a common pattern.

### What does Trivy scan for?

Trivy is an open-source vulnerability scanner by Aqua Security. It scans:
- OS packages (Alpine, Debian, Ubuntu, Amazon Linux)
- Language-specific packages (pip, npm, gem, cargo)
- Container image layers (checks each layer's installed packages)

CVE databases used: NVD, Red Hat, Debian, Alpine, GitHub Advisory.

### What is the GitOps model and how does Jenkins fit into it?

GitOps is an operational model where Git is the single source of truth for both application code and infrastructure state. Changes are applied to the system by committing to Git, not by running commands directly.

In this project:
- Jenkins is the **CI tool** — it builds, tests, scans, and pushes artefacts
- Jenkins also writes the deployment manifest back to Git (the GitOps trigger)
- ArgoCD is the **CD tool** — it watches Git and reconciles the cluster to match

Jenkins does not interact with Kubernetes directly. This separation means the cluster state is always auditable from Git history.

---

## 13. Troubleshooting Reference

### Jenkins UI not loading

```bash
# Check service status on master
ssh -i ~/.ssh/flask-cicd-gitops-dev-key.pem ec2-user@54.76.201.117 \
    'sudo systemctl status jenkins --no-pager'

# View recent logs
ssh -i ~/.ssh/flask-cicd-gitops-dev-key.pem ec2-user@54.76.201.117 \
    'sudo journalctl -u jenkins -n 50 --no-pager'

# Restart Jenkins
ssh -i ~/.ssh/flask-cicd-gitops-dev-key.pem ec2-user@54.76.201.117 \
    'sudo systemctl restart jenkins'
```

### Slave not connecting to master

- Verify JNLP port 50000 is open in the slave security group from the master security group
- Verify the slave node is configured with the correct private IP (10.0.10.129)
- Check slave agent logs: **Manage Jenkins → Nodes → slave → Log**

### Pipeline fails at `docker build` on slave

```bash
# Verify Docker is running on slave
ssh -J ec2-user@54.76.201.117 ec2-user@10.0.10.129 \
    'sudo systemctl status docker'

# Verify jenkins user can run docker
ssh -J ec2-user@54.76.201.117 ec2-user@10.0.10.129 \
    'id jenkins; groups jenkins'
```

### `withCredentials` block throws "No such credential"

The credential ID in the Jenkinsfile must exactly match the ID set in **Manage Jenkins → Credentials**. Check for spaces or typos: `dockerhub-credentials` vs `dockerhub_credentials`.

### `git push` fails in `pushManifest`

```
error: failed to push some refs to 'https://github.com/...'
hint: Updates were rejected because the remote contains work that you do not have locally
```

Cause: Another build pushed a manifest commit between this build's checkout and its push step.
Fix: In the Jenkinsfile `publishManifest` step, add a `git pull --rebase` before the push.

### Trivy reports vulnerabilities but pipeline should not fail

Change `--exit-code 1` to `--exit-code 0` in `scanImage.groovy` to make the scan advisory-only (report without failing). This is appropriate for MEDIUM/HIGH findings when a fix is not yet available but you still want the report archived.

### Jenkins build triggered by its own manifest push (infinite loop)

Ensure `[skip ci]` is present in the commit message inside `pushManifest.groovy`. Also verify the GitHub Integration plugin is configured to honour `[skip ci]`.

---

*Stage 6 complete when: pipeline runs end-to-end from a code push, a new Docker image lands in Docker Hub tagged with the build number, and the Kubernetes overlay manifest is updated in Git.*

*Next: [Stage 7 — ArgoCD GitOps](../argocd/README.md)*
