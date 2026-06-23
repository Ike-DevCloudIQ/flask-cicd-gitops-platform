# Stage 3 Notes: Kubernetes with Kustomize

This guide explains Stage 3 so you understand not just what was created, but why each decision matters.

## 1) Stage 3 Goal

Build a clean Kubernetes deployment model using:
- A reusable base for shared manifests
- Environment overlays for dev and prod differences
- Health, resilience, and resource controls for production readiness

The outcome is a GitOps-friendly structure that ArgoCD can consume later.

## 2) Folder Layout and Purpose

kubernetes/
- base/
  - namespace.yaml
  - deployment.yaml
  - service.yaml
  - kustomization.yaml
- overlays/
  - dev/
    - kustomization.yaml
    - deployment-patch.yaml
  - prod/
    - kustomization.yaml
    - deployment-patch.yaml

How to think about it:
- base = shared truth for all environments
- overlays = controlled differences per environment

## 3) Base Manifests Explained

### namespace.yaml
Defines an isolated namespace for the application.

Why this matters:
- Separates workloads from other apps
- Makes RBAC, quotas, and cleanup easier

### deployment.yaml
Defines pods and rollout behavior for the Flask app.

Key fields and why they matter:
- replicas: 2
  - Always keep 2 pods running for resilience and availability
- selector.matchLabels and template.metadata.labels
  - Must match exactly so Deployment can manage the right pods
- image
  - Uses a tagged container image for deterministic deployments
- imagePullPolicy: IfNotPresent
  - Faster startup in many environments while still pulling when missing
- livenessProbe on /health
  - Restarts unhealthy containers automatically
- readinessProbe on /health
  - Keeps unhealthy pods out of service traffic
- resources.requests
  - Tells scheduler the minimum CPU/memory needed
- resources.limits
  - Prevents a pod from over-consuming node resources

### service.yaml
Exposes the app internally and externally.

Key fields and why they matter:
- type: LoadBalancer
  - Cloud provider creates an external load balancer
- selector
  - Routes traffic only to pods with matching labels
- port 80 to targetPort 5000
  - Standard HTTP entry with app container port mapping

### base/kustomization.yaml
Composes base resources and shared labels.

Key concepts:
- resources
  - Includes namespace, deployment, and service
- labels
  - Applies consistent metadata to all generated resources
- configMapGenerator
  - Creates a ConfigMap with app_env value for runtime configuration

## 4) Overlays Explained

### dev overlay
Purpose:
- Lower cost and faster feedback loop

Changes made in dev:
- replicas reduced to 1
- lower resource requests and limits
- image set to the stage build tag
- app_env merged as dev

### prod overlay
Purpose:
- Higher availability and safer production behavior

Changes made in prod:
- replicas increased to 3
- higher resource requests and limits
- image set to a versioned release tag
- pod anti-affinity to spread pods across nodes when possible
- app_env merged as prod

Why pod anti-affinity matters:
- Reduces risk of all replicas landing on one node
- Improves fault tolerance during node failures

## 5) Kustomize Patch Matching (Important Lesson)

A common error occurred earlier:
- no matches for Id Deployment.v1.apps/flask-app.[noNs]

Root cause:
- Patch file targeted a Deployment without namespace, but base Deployment was namespaced.

Fix used:
- Add namespace in patch metadata
- Use modern patches syntax with explicit target in overlay kustomization

This ensures the patch is applied to the exact object.


## 6) How to Render and Validate

You do not need standalone kustomize binary if kubectl has built-in support.

Render manifests:
- kubectl kustomize kubernetes/base
- kubectl kustomize kubernetes/overlays/dev
- kubectl kustomize kubernetes/overlays/prod

If your current kubectl context points to an unreachable cluster, rendering still works.

Client dry-run note:
- kubectl apply --dry-run=client -k ... may still attempt API discovery against current context
- If your cluster endpoint is unreachable, you can still trust successful kubectl kustomize rendering for structure checks

## 7) Practical Learning Summary

What I learned in Stage 3:
- How to structure Kubernetes manifests for scale
- Why base and overlays are better than copy-paste manifests
- How health probes protect reliability
- How requests and limits improve cluster stability
- How environment-specific patches keep config clean
- How to debug Kustomize patch target errors
