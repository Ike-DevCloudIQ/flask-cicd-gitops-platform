# Stage 7 - ArgoCD GitOps Continuous Delivery

This stage connects your existing CI pipeline (Jenkins) to Kubernetes CD using ArgoCD.

## Goal

Make Git the single source of truth for deployment state:
- Jenkins updates image tag in `kubernetes/overlays/dev/deployment-patch.yaml`
- Jenkins pushes that commit to `main`
- ArgoCD detects the manifest change and applies it to the cluster automatically

## Files

- `argocd/project.yaml` - AppProject scoping source repos and destination namespace
- `argocd/application.yaml` - Application targeting `kubernetes/overlays/dev`

## Prerequisites

- Kubernetes cluster reachable via `kubectl`
- Existing namespace `flask-app` already present
- Repo: `https://github.com/Ike-DevCloudIQ/flask-cicd-gitops-platform.git`

## Install ArgoCD

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

Wait for readiness:

```bash
kubectl get pods -n argocd
```

All pods should become `Running`.

## Expose ArgoCD Server (quick dev access)

```bash
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
kubectl get svc argocd-server -n argocd -w
```

Use the EXTERNAL-IP with https.

## Get Initial Admin Password

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 --decode; echo
```

Username is `admin`.

## Apply GitOps Project and Application

From repository root:

```bash
kubectl apply -f argocd/project.yaml
kubectl apply -f argocd/application.yaml
```

Verify:

```bash
kubectl get app -n argocd
kubectl describe app flask-app-dev -n argocd
```

## Enable Auto-Sync Behavior

Already configured in `application.yaml`:
- `prune: true` - removes resources no longer in Git
- `selfHeal: true` - reverts drift to desired Git state

## End-to-End Validation

1. Trigger Jenkins pipeline (or push a code change)
2. Ensure Jenkins commits a new image tag to `main`
3. In ArgoCD UI, observe app status moving from `OutOfSync` to `Synced` and `Healthy`
4. Validate cluster deployment image:

```bash
kubectl -n flask-app get deploy flask-app -o jsonpath='{.spec.template.spec.containers[0].image}'; echo
```

Image should match latest Jenkins build tag.

## Common Issues

### Application shows `Unknown` or `OutOfSync`
- Check repo URL and path in `application.yaml`
- Confirm branch contains latest manifest commit

### Application sync fails
- Check ArgoCD controller logs:

```bash
kubectl logs -n argocd deploy/argocd-application-controller
```

### Namespace or RBAC errors
- Confirm `flask-app` namespace exists
- Confirm destination namespace in Application matches actual manifests

### `x509: certificate signed by unknown authority` during image pulls
In some local environments (Docker Desktop + kind/minikube behind enterprise TLS interception),
cluster nodes cannot trust external registries even when your host Docker can.

Symptoms:
- ArgoCD pods are `ErrImagePull` or `ImagePullBackOff`
- App workload pods fail to pull from Docker Hub/Quay/ECR

Local lab workaround:
1. Use minikube context
```bash
kubectl config use-context minikube
```
2. Preload ArgoCD images into minikube
```bash
images=$(kubectl get deploy,statefulset -n argocd -o jsonpath='{..image}' | tr ' ' '\n' | sort -u)
print -l $images | while IFS= read -r img; do
  [ -z "$img" ] && continue
  docker pull "$img"
  minikube image load "$img"
done
```
3. Patch ArgoCD workloads to avoid forced remote pull on each restart
```bash
kubectl get deploy,statefulset -n argocd -o json | jq -r '.items[] | .kind + "/" + .metadata.name + "|" + ((.spec.template.spec.initContainers // []) | length | tostring) + "|" + ((.spec.template.spec.containers // []) | length | tostring)' | while IFS='|' read -r kindname initCount ctrCount; do
  patch='['
  first=1
  i=0
  while [ $i -lt $initCount ]; do
    op="{\"op\":\"replace\",\"path\":\"/spec/template/spec/initContainers/$i/imagePullPolicy\",\"value\":\"IfNotPresent\"}"
    if [ $first -eq 1 ]; then patch="$patch$op"; first=0; else patch="$patch,$op"; fi
    i=$((i+1))
  done
  j=0
  while [ $j -lt $ctrCount ]; do
    op="{\"op\":\"replace\",\"path\":\"/spec/template/spec/containers/$j/imagePullPolicy\",\"value\":\"IfNotPresent\"}"
    if [ $first -eq 1 ]; then patch="$patch$op"; first=0; else patch="$patch,$op"; fi
    j=$((j+1))
  done
  patch="$patch]"
  kubectl -n argocd patch "$kindname" --type='json' -p "$patch"
done
```

4. For application images, preload the specific tag then restart the pod
```bash
img=$(kubectl -n flask-app get deploy flask-app -o jsonpath='{.spec.template.spec.containers[0].image}')
docker pull "$img"
minikube image load "$img"
kubectl -n flask-app delete pod -l app=flask-app
```

Note: this is a local development workaround. In production, fix trust chain/CA configuration at node runtime level.

## Helper Script (Recommended for Local Minikube)

To avoid repeating the image preload steps whenever Jenkins updates the tag, run:

```bash
bash scripts/sync-minikube-image.sh
```

Optional arguments:

```bash
bash scripts/sync-minikube-image.sh <namespace> <deployment>
```

Example:

```bash
bash scripts/sync-minikube-image.sh flask-app flask-app
```

What it does:
- Reads the currently desired deployment image
- Pulls it with Docker
- Loads it into minikube cache
- Deletes pods stuck in `ImagePullBackOff`/`ErrImagePull`
- Waits for deployment rollout to complete

## Stage 7 Completion Criteria

- ArgoCD installed and reachable
- `flask-app-dev` Application exists and syncs successfully
- Jenkins manifest commits trigger ArgoCD deployment updates
- Cluster deployment image follows Git automatically
