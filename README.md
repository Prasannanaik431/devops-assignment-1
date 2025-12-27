# DevOps Assignment - FastAPI Kubernetes Deployment

A complete DevOps workflow for deploying a containerized FastAPI application on a self-managed Kubernetes cluster using Infrastructure as Code (OpenTofu), CI/CD pipelines (GitHub Actions), and monitoring (Prometheus).

## 📋 Table of Contents

- [Architecture Overview](#architecture-overview)
- [Quick Start](#quick-start)
- [Infrastructure Setup (OpenTofu)](#infrastructure-setup-opentofu)
- [Kubernetes Cluster](#kubernetes-cluster)
- [Application Deployment](#application-deployment)
- [CI/CD Pipeline](#cicd-pipeline)
- [Load Balancing](#load-balancing)
- [Monitoring](#monitoring)
- [Scaling](#scaling)

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                     GitHub Actions CI/CD                        │
│  ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────────┐  │
│  │  Lint   │───▶│  Build  │───▶│  Scan   │───▶│   Deploy    │  │
│  └─────────┘    └─────────┘    └─────────┘    └─────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                                       │
                                       ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Kubernetes Cluster (3 VMs)                   │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │              Control Plane (devops-instance-1)          │   │
│  │  ┌──────────┐ ┌──────────────┐ ┌──────────┐ ┌────────┐  │   │
│  │  │ API      │ │ Controller   │ │Scheduler │ │ etcd   │  │   │
│  │  │ Server   │ │ Manager      │ │          │ │        │  │   │
│  │  └──────────┘ └──────────────┘ └──────────┘ └────────┘  │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─────────────────────┐       ┌─────────────────────┐         │
│  │ Worker Node 1       │       │ Worker Node 2       │         │
│  │ (devops-instance-2) │       │ (devops-instance-3) │         │
│  │  ┌─────────────┐    │       │  ┌─────────────┐    │         │
│  │  │ FastAPI Pod │    │       │  │ FastAPI Pod │    │         │
│  │  └─────────────┘    │       │  └─────────────┘    │         │
│  └─────────────────────┘       └─────────────────────┘         │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                   NodePort Service (30279)              │   │
│  │                   Load Balancing Layer                  │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

## 🚀 Quick Start

### Prerequisites

- 3 Ubuntu VMs with SSH access
- OpenTofu/Terraform installed locally
- Docker installed locally
- kubectl installed locally

### 1. Clone and Configure

```bash
git clone <repository-url>
cd devops-assignment

# Update VM IPs in opentofu/variables.tf
```

### 2. Deploy Infrastructure with OpenTofu

```bash
cd opentofu
tofu init
tofu apply
```

This will:
- Install containerd and Kubernetes on all VMs
- Initialize the control plane with kubeadm
- Install Flannel CNI for pod networking
- Join worker nodes to the cluster
- Create dev, stage, and prod namespaces

### 3. Deploy Application

```bash
# SSH to control plane
ssh -i ~/.ssh/devops-assignment-prasanna prasanna@<CONTROL_PLANE_IP>

# Deploy to dev namespace
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: fastapi
  namespace: dev
spec:
  replicas: 2
  selector:
    matchLabels:
      app: fastapi
  template:
    metadata:
      labels:
        app: fastapi
    spec:
      containers:
        - name: fastapi
          image: prasannasn/fastapi-devops:latest
          ports:
            - containerPort: 8000
---
apiVersion: v1
kind: Service
metadata:
  name: fastapi-lb
  namespace: dev
spec:
  type: NodePort
  selector:
    app: fastapi
  ports:
    - port: 80
      targetPort: 8000
EOF
```

## 📦 Infrastructure Setup (OpenTofu)

### File Structure

```
opentofu/
├── main.tf           # Main cluster provisioning
├── variables.tf      # Configuration variables
├── outputs.tf        # Output values
└── provider.tf       # Provider configuration
```

### Key Features

- **Idempotent Provisioning**: Safe to re-run
- **Complete Automation**: From bare VMs to running cluster
- **Internal/External IP Handling**: Supports cloud VMs with NAT

### Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `vm_external_ips` | External IPs for SSH access | See variables.tf |
| `vm_internal_ips` | Internal IPs for cluster communication | See variables.tf |
| `ssh_user` | SSH username | prasanna |
| `ssh_key` | Path to SSH private key | ~/.ssh/devops-assignment-prasanna |

## ⚙️ Kubernetes Cluster

### Components

- **Kubernetes Version**: 1.30.14
- **Container Runtime**: containerd 2.1.3
- **CNI**: Flannel (pod-network-cidr: 10.244.0.0/16)
- **OS**: Ubuntu 25.10

### Namespaces

| Namespace | Purpose |
|-----------|---------|
| `dev` | Development environment |
| `stage` | Staging environment |
| `prod` | Production environment |

## 🔄 CI/CD Pipeline

### Workflow Overview

```
Push to branch → Code Quality → Build Image → Security Scan → Deploy → Verify
```

### Branch Mapping

| Branch | Namespace | Environment |
|--------|-----------|-------------|
| `dev` | dev | Development |
| `stage` | stage | Staging |
| `main` | prod | Production |

### Required Secrets

Add these secrets to your GitHub repository:

| Secret | Description |
|--------|-------------|
| `DOCKERHUB_USERNAME` | Docker Hub username |
| `DOCKERHUB_TOKEN` | Docker Hub access token |
| `KUBECONFIG` | Base64-encoded kubeconfig |

### Generate KUBECONFIG Secret

```bash
./scripts/get-kubeconfig.sh
# Copy the base64 output and add as KUBECONFIG secret in GitHub
```

## ⚖️ Load Balancing

The application uses Kubernetes **NodePort** service for load balancing:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: fastapi-lb
spec:
  type: NodePort
  selector:
    app: fastapi
  ports:
    - port: 80
      targetPort: 8000
      nodePort: 30279  # Automatically assigned
```

Access the application via any node IP:

```bash
curl http://<ANY_NODE_EXTERNAL_IP>:30279/
```

## 📊 Monitoring

### Prometheus Setup

Deploy Prometheus for monitoring:

```bash
kubectl apply -k k8s/monitoring/
```

### Metrics Collected

- Kubernetes cluster health
- Pod CPU and memory usage
- Application availability
- Request metrics (via annotations)

### Pod Annotations for Scraping

```yaml
annotations:
  prometheus.io/scrape: "true"
  prometheus.io/port: "8000"
  prometheus.io/path: "/"
```

## 📈 Scaling

### Horizontal Scaling

Increase replicas via deployment:

```bash
kubectl scale deployment fastapi -n dev --replicas=5
```

Or with HPA (Horizontal Pod Autoscaler) in production:

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
    name: prod-fastapi
  minReplicas: 3
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
```

### Vertical Scaling

Update VM resources via cloud provider and adjust pod resource limits in Kustomize overlays.

## 📁 Project Structure

```
devops-assignment/
├── app/                          # FastAPI application code
├── .github/
│   └── workflows/
│       └── ci-cd.yaml           # CI/CD pipeline
├── k8s/
│   ├── base/                    # Base Kubernetes manifests
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── kustomization.yaml
│   ├── overlays/                # Environment-specific configs
│   │   ├── dev/
│   │   ├── stage/
│   │   └── prod/
│   ├── monitoring/              # Prometheus stack
│   └── namespaces.yaml
├── opentofu/                    # Infrastructure as Code
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── provider.tf
├── scripts/                     # Helper scripts
│   └── get-kubeconfig.sh
├── docs/                        # Documentation
├── Dockerfile                   # Application container
├── requirements.txt             # Python dependencies
└── README.md
```

## 🔧 Troubleshooting

### Cluster Issues

```bash
# Check node status
kubectl get nodes -o wide

# Check kube-system pods
kubectl get pods -n kube-system

# Check kubelet logs
sudo journalctl -u kubelet -f
```

### Pod Issues

```bash
# Describe pod for events
kubectl describe pod <pod-name> -n <namespace>

# Check logs
kubectl logs <pod-name> -n <namespace>
```

### CNI Issues

```bash
# Reset CNI on worker nodes
sudo ip link delete cni0
sudo ip link delete flannel.1
sudo rm -rf /etc/cni/net.d/*
sudo systemctl restart kubelet
```

## 📜 License

This project is part of a DevOps assignment. All rights reserved.
