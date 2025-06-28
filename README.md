# 🔧 Enhanced DevOps Assignment

## Objective

Build a production-grade infrastructure and CI/CD system for the FastAPI app that meets scalability, reliability, security, and observability needs.

## Application Setup

Keep as-is:

- FastAPI app lives in app/main.py
- Use `make run-server` to run locally

## 1. Infrastructure Details

- Deploy FastAPI app using Helm or Kubernetes manifests
- Use separate namespaces for dev and prod
- Add Nginx ingress controller with proper routing
- Set up cert-manager with Let's Encrypt to auto-issue TLS certificates

## 2. CI/CD

Use GitHub Actions or GitLab CI to:

- Run tests (pytest)
- Lint (flake8 or black)
- Build and push Docker image to a container registry (e.g., GitHub Container Registry or ECR)
- Deploy to Kubernetes via kubectl or Helm
- Set up blue-green or canary deployments using Argo Rollouts or custom strategy

## 3. Monitoring & Observability

Integrate:

- Prometheus for metrics
- Grafana dashboards (pre-built FastAPI/uvicorn dashboard)
- Loki for centralized logging
- Kubernetes metrics-server for pod resource usage

**Bonus:**

- Set up alerts (Grafana + Slack webhook)

## 4. Secrets & Configuration Management

Use:

- Sealed Secrets or HashiCorp Vault or K8s Secrets with encryption at rest
- Externalized config with ConfigMap

## 5. Security Best Practices

- Scan Docker image with Trivy
- Role-based access control (RBAC) on the K8s cluster

## 6. Auto-Scaling

- Document how the app can scale horizontally, no need to implement it

## Deliverables

GitHub Repo with:

- Dockerfile
- K8s manifests / Helm charts
- .github/workflows/main.yml or similar CI/CD pipeline
- Dashboard screenshots and alerts setup

README with:

- System architecture diagram
- Deployment instructions
- Monitoring and scaling strategy
- Security measures in place

## Stretch Goals (For Rockstar Impact)

- Add a second microservice (maybe a /timezones API)
- Use Service Mesh (e.g., Istio or Linkerd) for observability and mTLS
- Implement GitOps with ArgoCD
