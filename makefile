# =============================================================================
# Makefile for DevOps Assignment
# =============================================================================

.PHONY: help run-server docker-build docker-run test lint deploy-dev deploy-stage deploy-prod

# Default target
help:
	@echo "Available targets:"
	@echo "  run-server      - Run the FastAPI server locally"
	@echo "  docker-build    - Build Docker image"
	@echo "  docker-run      - Run Docker container locally"
	@echo "  test            - Run tests (placeholder)"
	@echo "  lint            - Run linting checks"
	@echo "  deploy-dev      - Deploy to dev namespace"
	@echo "  deploy-stage    - Deploy to stage namespace"
	@echo "  deploy-prod     - Deploy to prod namespace"
	@echo "  infra-plan      - Plan infrastructure changes"
	@echo "  infra-apply     - Apply infrastructure changes"
	@echo "  monitoring      - Deploy Prometheus monitoring"

# =============================================================================
# Local Development
# =============================================================================
run-server:
	uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

lint:
	pip install flake8 black isort
	flake8 app --count --select=E9,F63,F7,F82 --show-source --statistics
	black --check app || true
	isort --check-only app || true

test:
	@echo "No tests configured yet"

# =============================================================================
# Docker
# =============================================================================
IMAGE_NAME ?= fastapi
IMAGE_TAG ?= latest

docker-build:
	docker build -t $(IMAGE_NAME):$(IMAGE_TAG) .

docker-run:
	docker run -p 8000:8000 $(IMAGE_NAME):$(IMAGE_TAG)

docker-push:
	docker push $(IMAGE_NAME):$(IMAGE_TAG)

# =============================================================================
# Kubernetes Deployments
# =============================================================================
deploy-namespaces:
	kubectl apply -f k8s/namespaces.yaml

deploy-gateway:
	kubectl apply -f k8s/envoy-gateway/install.yaml

deploy-dev: deploy-namespaces
	kubectl apply -k k8s/overlays/dev/

deploy-stage: deploy-namespaces
	kubectl apply -k k8s/overlays/stage/

deploy-prod: deploy-namespaces
	kubectl apply -k k8s/overlays/prod/

deploy-all: deploy-namespaces deploy-gateway deploy-dev deploy-stage deploy-prod

# =============================================================================
# Monitoring
# =============================================================================
monitoring:
	kubectl apply -k k8s/monitoring/

monitoring-port-forward:
	kubectl port-forward -n monitoring svc/prometheus 9090:9090

# =============================================================================
# Infrastructure (OpenTofu)
# =============================================================================
infra-init:
	cd opentofu && tofu init

infra-plan:
	cd opentofu && tofu plan

infra-apply:
	cd opentofu && tofu apply

infra-destroy:
	cd opentofu && tofu destroy

infra-output:
	cd opentofu && tofu output

# =============================================================================
# Cluster Operations
# =============================================================================
cluster-status:
	kubectl get nodes
	@echo ""
	kubectl get pods -A

cluster-logs-dev:
	kubectl logs -n dev -l app=fastapi --tail=100

cluster-logs-stage:
	kubectl logs -n stage -l app=fastapi --tail=100

cluster-logs-prod:
	kubectl logs -n prod -l app=fastapi --tail=100

# =============================================================================
# Cleanup
# =============================================================================
clean:
	docker rmi $(IMAGE_NAME):$(IMAGE_TAG) || true
	find . -type d -name __pycache__ -exec rm -rf {} + || true
	find . -type f -name "*.pyc" -delete || true
