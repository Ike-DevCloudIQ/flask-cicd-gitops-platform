# Stage 3: Kubernetes Manifests + Kustomize

**Checklist:**
- [ ] Kustomize base directory structure
- [ ] Base deployment.yaml with probes
- [ ] Dev overlay kustomization.yaml
- [ ] `kubectl kustomize` build output
- [ ] `minikube status` showing cluster running
- [ ] Namespace and deployment created
- [ ] Pod running with RUNNING status
- [ ] Service endpoint
- [ ] Health endpoint test via port-forward
- [ ] Pod describe showing resources and security context

**Files to add here:**
- `01-base-structure.png`
- `02-deployment-yaml.png`
- `03-dev-kustomization.png`
- `04-kustomize-build.png`
- `05-minikube-status.png`
- `06-namespace-deploy.png`
- `07-pod-running.png`
- `08-service.png`
- `09-health-check.png`
- `10-pod-describe.png`
- `command-outputs.txt`

**Context:**
Demonstrates mastery of Kubernetes declarative configs, overlays for environment-specific configs, and proper resource/probe setup.
