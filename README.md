# FastAPI DevOps Assignment

A complete DevOps implementation featuring Infrastructure as Code, CI/CD pipeline, Kubernetes deployment, monitoring, and auto-scaling.

## 📋 Table of Contents

- [Architecture Overview](#architecture-overview)
- [Infrastructure Setup](#infrastructure-setup)
- [CI/CD Pipeline](#cicd-pipeline)
- [Deployment Environments](#deployment-environments)
- [Monitoring Strategy](#monitoring-strategy)
- [Scalability](#scalability)
- [Quick Start](#quick-start)

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              ARCHITECTURE                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────┐     ┌─────────────┐     ┌─────────────────────────────┐   │
│  │   GitHub    │────▶│  GitHub     │────▶│     Docker Hub              │   │
│  │   (Code)    │     │  Actions    │     │  prasannasn/fastapi-devops  │   │
│  └─────────────┘     └──────┬──────┘     └─────────────────────────────┘   │
│                             │                                                │
│                             ▼                                                │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │                    Kubernetes Cluster (3 VMs)                          │  │
│  │  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐          │  │
│  │  │ Control Plane   │ │  Worker Node 1  │ │  Worker Node 2  │          │  │
│  │  │ (10.160.0.3)    │ │  (10.160.0.4)   │ │  (10.160.0.5)   │          │  │
│  │  │                 │ │                 │ │                 │          │  │
│  │  │ • API Server    │ │ • FastAPI Pods  │ │ • FastAPI Pods  │          │  │
│  │  │ • etcd          │ │ • Flannel CNI   │ │ • Flannel CNI   │          │  │
│  │  │ • Scheduler     │ │ • kube-proxy    │ │ • kube-proxy    │          │  │
│  │  │ • Controller    │ │                 │ │                 │          │  │
│  │  └─────────────────┘ └─────────────────┘ └─────────────────┘          │  │
│  │                                                                        │  │
│  │  Namespaces:                                                           │  │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌─────────────┐            │  │
│  │  │   dev    │  │  stage   │  │   prod   │  │  monitoring │            │  │
│  │  │ :30080   │  │ :30081   │  │ :30082   │  │   :30090    │            │  │
│  │  │ 2 replicas│  │ 2 replicas│  │ 3 replicas│  │ Prometheus  │            │  │
│  │  └──────────┘  └──────────┘  └──────────┘  └─────────────┘            │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 🔧 Infrastructure Setup

### Prerequisites

- Google Cloud Platform account
- `gcloud` CLI configured
- SSH key pair for VM access
- OpenTofu/Terraform installed

### Infrastructure Components

| Component | Technology | Purpose |
|-----------|------------|---------|
| IaC | OpenTofu | Infrastructure provisioning |
| Container Runtime | containerd | Running containers |
| Kubernetes | kubeadm v1.30 | Container orchestration |
| CNI | Flannel | Pod networking |
| Load Balancer | NodePort Services | Traffic distribution |

### VM Configuration

| VM | Role | Internal IP | External IP | Resources |
|----|------|-------------|-------------|-----------|
| devops-instance-1 | Control Plane | 10.160.0.3 | 34.14.169.168 | 2 vCPU, 4GB RAM |
| devops-instance-2 | Worker Node | 10.160.0.4 | 34.100.156.67 | 2 vCPU, 4GB RAM |
| devops-instance-3 | Worker Node | 10.160.0.5 | 34.14.213.230 | 2 vCPU, 4GB RAM |

### OpenTofu Setup

```bash
cd opentofu/
tofu init
tofu plan
tofu apply
```

---

## 🚀 CI/CD Pipeline

### Pipeline Stages

```
┌──────────────┐    ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│ Code Quality │───▶│    Build     │───▶│   Security   │───▶│    Deploy    │
│              │    │              │    │    Scan      │    │              │
│ • flake8     │    │ • Docker     │    │ • Trivy      │    │ • kubectl    │
│ • black      │    │ • Push to    │    │ • CVE check  │    │ • Rollout    │
│ • isort      │    │   Docker Hub │    │              │    │ • Verify     │
└──────────────┘    └──────────────┘    └──────────────┘    └──────────────┘
```

### Branch to Environment Mapping

| Branch | Environment | Namespace | NodePort | Replicas |
|--------|-------------|-----------|----------|----------|
| `prasanna` | Development | dev | 30080 | 2 |
| `stage` | Staging | stage | 30081 | 2 |
| `main` | Production | prod | 30082 | 3 |

### GitHub Actions Workflow

Located at: `.github/workflows/ci-cd.yaml`

**Required Secrets:**
- `DOCKERHUB_USERNAME` - Docker Hub username
- `DOCKERHUB_TOKEN` - Docker Hub access token
- `SSH_PRIVATE_KEY` - SSH private key for cluster access
- `CONTROL_PLANE_IP` - Control plane external IP

### Triggering Deployments

```bash
# Automatic: Push to branch
git push origin prasanna  # Deploys to dev
git push origin stage     # Deploys to staging
git push origin main      # Deploys to production

# Manual: Workflow dispatch
# Go to Actions tab → Run workflow → Select environment
```

---

## 🌍 Deployment Environments

### Development (dev)

- **Purpose**: Feature testing, debugging
- **Replicas**: 2
- **Resources**: 64Mi-256Mi memory, 50m-500m CPU
- **Endpoint**: `http://<worker-ip>:30080`

### Staging (stage)

- **Purpose**: Pre-production testing, QA
- **Replicas**: 2
- **Resources**: 128Mi-256Mi memory, 100m-500m CPU
- **Endpoint**: `http://<worker-ip>:30081`

### Production (prod)

- **Purpose**: Live traffic, end users
- **Replicas**: 3 (auto-scales 2-10)
- **Resources**: 128Mi-512Mi memory, 100m-1000m CPU
- **Endpoint**: `http://<worker-ip>:30082`
- **Features**: HPA enabled, Prometheus monitoring

---

## 📊 Monitoring Strategy

### Prometheus Setup

- **Namespace**: monitoring
- **NodePort**: 30090
- **Scrape Interval**: 15s

### Metrics Collected

| Metric Type | Source | Purpose |
|-------------|--------|---------|
| Application | FastAPI pods | Request latency, error rates |
| Container | cAdvisor | CPU, memory, network |
| Kubernetes | kube-state-metrics | Pod, deployment health |

### Accessing Prometheus

```bash
# Via NodePort (if firewall allows)
http://<worker-ip>:30090

# Via kubectl port-forward
kubectl port-forward -n monitoring svc/prometheus 9090:9090
# Then access: http://localhost:9090
```

### Alerting (Future Enhancement)

Configure AlertManager for:
- High CPU/Memory usage (>80%)
- Pod restart counts
- Response time degradation
- Service availability

---

## 📈 Scalability

### Horizontal Pod Autoscaler (HPA)

Production environment has HPA configured:

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: fastapi-hpa
  namespace: prod
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: fastapi
  minReplicas: 2
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 80
```

### Scaling Architecture

```
                    ┌─────────────────────────────────────────┐
                    │           SCALING DIAGRAM               │
                    └─────────────────────────────────────────┘

   Traffic Increase                              Traffic Decrease
         │                                              │
         ▼                                              ▼
┌─────────────────┐                          ┌─────────────────┐
│  HPA Monitors   │                          │  HPA Monitors   │
│  CPU/Memory     │                          │  CPU/Memory     │
│  Metrics        │                          │  Metrics        │
└────────┬────────┘                          └────────┬────────┘
         │                                            │
         ▼                                            ▼
┌─────────────────┐                          ┌─────────────────┐
│ CPU > 70% or    │                          │ CPU < 50% and   │
│ Memory > 80%    │                          │ Memory < 60%    │
└────────┬────────┘                          └────────┬────────┘
         │                                            │
         ▼                                            ▼
┌─────────────────┐                          ┌─────────────────┐
│  Scale UP       │                          │  Scale DOWN     │
│  (max: 10 pods) │                          │  (min: 2 pods)  │
└─────────────────┘                          └─────────────────┘

Current: 3 pods ──────▶ High Load: 10 pods ──────▶ Low Load: 2 pods
```

### Manual Scaling

```bash
# Scale deployment manually
kubectl scale deployment/fastapi -n prod --replicas=5

# Check HPA status
kubectl get hpa -n prod

# Watch scaling in action
kubectl get pods -n prod -w
```

### Vertical Scaling (Node Level)

To add more worker nodes:

1. Provision new VM with same specs
2. Install kubeadm, kubelet, containerd
3. Join cluster: `kubeadm join <control-plane>:6443 --token <token>`

---

## 🚀 Quick Start

### 1. Run Application Locally

```bash
# Install dependencies
pip install -r requirements.txt

# Run server
make run-server
# OR
uvicorn app.main:app --host 0.0.0.0 --port 8000

# Access: http://localhost:8000
```

### 2. Build Docker Image

```bash
docker build -t prasannasn/fastapi-devops:latest .
docker push prasannasn/fastapi-devops:latest
```

### 3. Deploy to Kubernetes

```bash
# Using kubectl
kubectl apply -f k8s/overlays/dev/

# Or trigger CI/CD
git push origin prasanna
```

### 4. Verify Deployment

```bash
# Check pods
kubectl get pods -A | grep fastapi

# Test endpoints
curl http://<worker-ip>:30080  # dev
curl http://<worker-ip>:30081  # stage
curl http://<worker-ip>:30082  # prod
```

---

## 📁 Project Structure

```
devops-assignment/
├── app/
│   └── main.py              # FastAPI application
├── k8s/
│   ├── base/                # Base Kubernetes manifests
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── kustomization.yaml
│   ├── overlays/            # Environment-specific configs
│   │   ├── dev/
│   │   ├── stage/
│   │   └── prod/
│   └── monitoring/          # Prometheus configs
├── opentofu/                # Infrastructure as Code
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── provider.tf
├── .github/
│   └── workflows/
│       └── ci-cd.yaml       # GitHub Actions pipeline
├── Dockerfile
├── requirements.txt
├── Makefile
└── README.md
```

---

## 🔒 Security

- Docker images scanned with Trivy
- Non-root container execution
- Resource limits on all pods
- RBAC for Prometheus
- SSH-based deployment (no exposed K8s API)

---

## 📝 License

This project is for educational purposes as part of a DevOps assignment.

---

## 👤 Author

Prasanna Naik
