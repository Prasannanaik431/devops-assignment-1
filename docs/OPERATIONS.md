# Operations Guide

This document provides operational procedures for managing the DevOps deployment.

## Table of Contents

- [Day-to-Day Operations](#day-to-day-operations)
- [Deployment Procedures](#deployment-procedures)
- [Scaling Procedures](#scaling-procedures)
- [Troubleshooting](#troubleshooting)
- [Disaster Recovery](#disaster-recovery)

---

## Day-to-Day Operations

### Checking Cluster Health

```bash
# Node status
kubectl get nodes -o wide

# All pods across namespaces
kubectl get pods -A

# Check specific environment
kubectl get pods -n dev
kubectl get pods -n stage
kubectl get pods -n prod
```

### Viewing Application Logs

```bash
# Development logs
make cluster-logs-dev

# Staging logs
make cluster-logs-stage

# Production logs
make cluster-logs-prod

# Stream logs in real-time
kubectl logs -n prod -l app=fastapi -f
```

### Monitoring Metrics

```bash
# Port-forward Prometheus
make monitoring-port-forward

# Access at http://localhost:9090

# Useful PromQL queries:
# - Pod count: count(kube_pod_info{namespace="prod"})
# - CPU usage: rate(container_cpu_usage_seconds_total{namespace="prod"}[5m])
# - Memory usage: container_memory_usage_bytes{namespace="prod"}
```

---

## Deployment Procedures

### Standard Deployment (via CI/CD)

1. Merge code to the target branch:
   - `dev` branch → deploys to dev namespace
   - `stage` branch → deploys to stage namespace
   - `main` branch → deploys to prod namespace

2. Monitor the GitHub Actions workflow

3. Verify deployment:
   ```bash
   kubectl get pods -n <namespace>
   kubectl rollout status deployment/<env>-fastapi -n <namespace>
   ```

### Manual Deployment

```bash
# Update image tag in kustomization.yaml
cd k8s/overlays/<env>/
# Edit kustomization.yaml with new image tag

# Apply changes
make deploy-<env>

# Verify
kubectl get pods -n <namespace>
```

### Rollback Procedure

```bash
# View rollout history
kubectl rollout history deployment/<env>-fastapi -n <namespace>

# Rollback to previous version
kubectl rollout undo deployment/<env>-fastapi -n <namespace>

# Rollback to specific revision
kubectl rollout undo deployment/<env>-fastapi -n <namespace> --to-revision=<N>

# Verify rollback
kubectl rollout status deployment/<env>-fastapi -n <namespace>
```

---

## Scaling Procedures

### Horizontal Scaling (Manual)

```bash
# Scale up
kubectl scale deployment/prod-fastapi -n prod --replicas=5

# Scale down
kubectl scale deployment/prod-fastapi -n prod --replicas=3

# Check HPA status
kubectl get hpa -n prod
kubectl describe hpa prod-fastapi-hpa -n prod
```

### Horizontal Scaling (Automatic)

The production environment uses HPA. To modify scaling parameters:

1. Edit `k8s/overlays/prod/hpa.yaml`
2. Apply changes:
   ```bash
   kubectl apply -f k8s/overlays/prod/hpa.yaml
   ```

### Vertical Scaling

1. **Update VM resources** (at cloud provider level)

2. **Update OpenTofu variables** (for documentation):
   ```hcl
   # opentofu/variables.tf
   variable "vm_cpu_cores" {
     default = 4  # Updated from 2
   }
   variable "vm_memory_gb" {
     default = 8  # Updated from 4
   }
   ```

3. **Update pod resource limits**:
   ```yaml
   # k8s/overlays/prod/kustomization.yaml
   # Increase limits in the patch section
   ```

4. **Apply changes**:
   ```bash
   make deploy-prod
   ```

---

## Troubleshooting

### Pod Not Starting

```bash
# Check pod status
kubectl describe pod <pod-name> -n <namespace>

# Check events
kubectl get events -n <namespace> --sort-by='.lastTimestamp'

# Common issues:
# - ImagePullBackOff: Check image name/tag and registry credentials
# - CrashLoopBackOff: Check application logs
# - Pending: Check resource availability and node capacity
```

### Application Errors

```bash
# View application logs
kubectl logs <pod-name> -n <namespace>

# Execute into container for debugging
kubectl exec -it <pod-name> -n <namespace> -- /bin/sh

# Check health endpoints
kubectl port-forward <pod-name> -n <namespace> 8080:8000
curl http://localhost:8080/
```

### Network Issues

```bash
# Check service endpoints
kubectl get endpoints -n <namespace>

# Check Gateway status
kubectl get gateway -n envoy-gateway-system
kubectl describe gateway envoy-gateway -n envoy-gateway-system

# Check HTTPRoute status
kubectl get httproute -A
kubectl describe httproute <route-name> -n <namespace>
```

### Resource Exhaustion

```bash
# Check node resources
kubectl top nodes

# Check pod resource usage
kubectl top pods -n <namespace>

# Check for evicted pods
kubectl get pods -n <namespace> --field-selector=status.phase=Failed
```

---

## Disaster Recovery

### Backup Procedures

```bash
# Backup all resources
kubectl get all -A -o yaml > backup/cluster-all.yaml

# Backup specific namespace
kubectl get all -n prod -o yaml > backup/prod-all.yaml

# Backup deployments and services
kubectl get deployment,service,hpa -n prod -o yaml > backup/prod-apps.yaml
```

### Restore Procedures

```bash
# Restore from backup
kubectl apply -f backup/prod-apps.yaml

# Verify restoration
kubectl get all -n prod
```

### Cluster Recovery

If the Kubernetes cluster needs to be rebuilt:

1. **Re-run OpenTofu**:
   ```bash
   cd opentofu
   tofu apply
   ```

2. **Re-initialize cluster** (on control plane):
   ```bash
   sudo /usr/local/bin/init-cluster.sh
   ```

3. **Rejoin worker nodes**:
   ```bash
   # Get new join command
   sudo /usr/local/bin/get-join-command.sh
   # Run on each worker
   ```

4. **Redeploy application stack**:
   ```bash
   make deploy-all
   make monitoring
   ```

---

## Runbook: Common Scenarios

### Scenario 1: High CPU Alert

1. Check current usage: `kubectl top pods -n prod`
2. If HPA is working, it should auto-scale
3. If at max replicas, consider:
   - Vertical scaling (increase pod limits)
   - Infrastructure scaling (add more nodes)

### Scenario 2: Application Crash

1. Check pod status: `kubectl get pods -n prod`
2. View logs: `kubectl logs <pod-name> -n prod --previous`
3. If recent deployment, rollback: `kubectl rollout undo deployment/prod-fastapi -n prod`
4. Investigate root cause in development

### Scenario 3: Node Failure

1. Check node status: `kubectl get nodes`
2. Pods will be automatically rescheduled to healthy nodes
3. If node needs replacement:
   - Remove from cluster: `kubectl delete node <node-name>`
   - Re-provision with OpenTofu
   - Rejoin cluster with kubeadm join

### Scenario 4: Envoy Gateway Issues

1. Check Gateway status: `kubectl get gateway -n envoy-gateway-system`
2. Check Envoy pods: `kubectl get pods -n envoy-gateway-system`
3. If needed, reinstall:
   ```bash
   helm uninstall envoy-gateway -n envoy-gateway-system
   helm install envoy-gateway oci://docker.io/envoyproxy/gateway-helm \
     --version v1.0.0 \
     --namespace envoy-gateway-system
   kubectl apply -f k8s/envoy-gateway/install.yaml
   ```


