# Stage 8: Hardening & Defense Readiness

**Checklist:**
- [ ] Kubernetes security context (runAsNonRoot, runAsUser, etc.)
- [ ] Pod running as non-root user (uid=100)
- [ ] Rollout history showing multiple revisions
- [ ] Rollback demonstration (undo command executed)
- [ ] Readiness and liveness probes configured
- [ ] Resource requests and limits set
- [ ] STAGE8-HARDENING-CHECKLIST.md visible
- [ ] Fresh Jenkins build #1931 Trivy gate evidence
- [ ] End-to-end flow diagram/visualization
- [ ] Final deployment status (all components healthy)

**Files to add here:**
- `01-security-context.png`
- `02-nonroot-pod.png`
- `03-rollout-history.png`
- `04-rollback-undo.png`
- `05-probes.png`
- `06-resource-limits.png`
- `07-checklist.png`
- `08-fresh-trivy-gate.png` ⭐ KEY EVIDENCE
- `09-end-to-end-flow.png`
- `10-final-status.png`
- `command-outputs.txt`

**Context:**
The capstone stage. Recruiter sees you didn't just build the system—you hardened it, tested recovery, documented everything, and proved it with authenticated evidence. This is what separates junior from senior engineers.
