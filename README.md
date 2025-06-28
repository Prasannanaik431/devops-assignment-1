# DevOps Assignment

## Objective

Build a production-grade infrastructure and CI/CD system for the FastAPI app that meets scalability, reliability, security, and observability needs.

---

## Application Setup

- FastAPI app lives in `app/main.py`
- Use `make run-server` to run locally
- Environment variables (refer `.env.example`):

  - `DUMMY_API_KEY`
  - `SECRET_MESSAGE`
  - `TIMEZONE_OFFSET`
  - `GREETING`

These variables will be managed via **Kubernetes ConfigMaps** and **Secrets** in the production deployment.

---

## 1. Infrastructure Details

- Deploy FastAPI app using Helm or Kubernetes manifests
- Use separate namespaces for `dev` and `prod`
- Add **Nginx ingress controller** with proper routing
- Set up **cert-manager** with Let's Encrypt to auto-issue TLS certificates

---

## 2. CI/CD

Use GitHub Actions or GitLab CI to:

- Run tests (`pytest`)
- Lint (`flake8` or `black`)
- Build and push Docker image to a container registry (e.g., GitHub Container Registry or ECR)
- Deploy to Kubernetes via `kubectl` or Helm
- Support **blue-green or canary deployments** using Argo Rollouts or a custom strategy

---

## 3. Monitoring & Observability

Integrate:

- **Prometheus** for metrics
- **Grafana dashboards** (e.g., FastAPI/uvicorn)
- **Loki** for centralized logging
- **Kubernetes metrics-server** for pod resource usage

**Bonus:**

- Set up alerts (e.g., Grafana + Slack webhook)

---

## 4. Secrets & Configuration Management

### ConfigMap

- `TIMEZONE_OFFSET` and `GREETING` are injected as **non-sensitive values** via a Kubernetes ConfigMap.
- This allows environment-specific configurations without modifying code.

### Secret

- `DUMMY_API_KEY` and `SECRET_MESSAGE` are handled via **Kubernetes Secrets**.
- For Git-safe workflows, Sealed Secrets or an external secrets manager (e.g., AWS Secrets Manager or HashiCorp Vault) is recommended.

---

## 5. Security Best Practices

- Scan Docker image with **Trivy**
- Enforce **RBAC** on Kubernetes cluster
- Use TLS with Ingress + cert-manager
- Secure secrets using encryption at rest or Git-safe secret strategies (e.g., Sealed Secrets)

---

## 6. Auto-Scaling

Document how the app can scale horizontally:

- Using **Horizontal Pod Autoscaler (HPA)** for CPU/memory-based scaling
- Using **Cluster Autoscaler** for node-level scaling

_No implementation required for this section._

---

## Deliverables

GitHub Repo with:

- `Dockerfile`
- `Kubernetes manifests` or `Helm charts`
- `.github/workflows/main.yml` or equivalent CI/CD config
- Dashboard screenshots and alerting setup
- ConfigMap and Secret definitions

README with:

- System architecture diagram
- Deployment instructions
- Monitoring and scaling strategy
- Config/Secret management details
- Security best practices

---

## Stretch Goals (For Rockstar Impact)

- Add a second microservice (e.g., `/timezones` API)
- Use a **Service Mesh** (e.g., Istio or Linkerd) for observability and mTLS
- Implement **GitOps** deployment flow with **ArgoCD**
