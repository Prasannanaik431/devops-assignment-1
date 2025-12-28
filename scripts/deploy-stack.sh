#!/bin/bash
# =============================================================================
# Full Stack Deployment Script
# =============================================================================
# Deploys the complete DevOps stack including:
# - Namespaces
# - Envoy Gateway
# - Prometheus Monitoring
# - FastAPI Application (all environments)
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_step() {
    echo -e "${GREEN}[STEP]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if kubectl is configured
if ! kubectl cluster-info &> /dev/null; then
    print_error "kubectl is not configured or cluster is not accessible"
    exit 1
fi

echo "=============================================="
echo "  DevOps Stack Deployment"
echo "=============================================="
echo ""

# Get the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

cd "$PROJECT_ROOT"

# =============================================================================
# Step 1: Create Namespaces
# =============================================================================
print_step "Creating namespaces (dev, stage, prod)..."
kubectl apply -f k8s/namespaces.yaml

# =============================================================================
# Step 2: Install Metrics Server (for HPA)
# =============================================================================
print_step "Installing Metrics Server for HPA..."
kubectl apply -f k8s/monitoring/metrics-server.yaml

echo "Waiting for Metrics Server to be ready..."
kubectl wait --for=condition=available deployment/metrics-server -n kube-system --timeout=120s || true

# =============================================================================
# Step 3: Install Gateway API CRDs
# =============================================================================
print_step "Installing Gateway API CRDs..."
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.0.0/standard-install.yaml

# =============================================================================
# Step 4: Install Envoy Gateway (via Helm if available, else skip)
# =============================================================================
print_step "Installing Envoy Gateway..."

if command -v helm &> /dev/null; then
    print_info "Helm found, installing Envoy Gateway via Helm..."
    
    helm repo add envoyproxy https://charts.envoyproxy.io || true
    helm repo update || true
    
    helm upgrade --install envoy-gateway envoyproxy/gateway-helm \
        --namespace envoy-gateway-system \
        --create-namespace \
        --wait \
        --timeout 5m || print_warning "Helm install failed, continuing..."
else
    print_warning "Helm not found. Installing Envoy Gateway via kubectl..."
    kubectl apply -f https://github.com/envoyproxy/gateway/releases/download/v1.0.0/install.yaml || true
fi

# Apply Gateway and GatewayClass resources
print_step "Applying Gateway resources..."
kubectl apply -f k8s/envoy-gateway/install.yaml || true

# =============================================================================
# Step 5: Deploy Prometheus Monitoring
# =============================================================================
print_step "Deploying Prometheus monitoring stack..."
kubectl apply -k k8s/monitoring/

echo "Waiting for Prometheus to be ready..."
kubectl wait --for=condition=available deployment/prometheus -n monitoring --timeout=120s || true

# =============================================================================
# Step 6: Build and Load Docker Image (for local testing)
# =============================================================================
print_step "Building Docker image..."

IMAGE_NAME="prasannanaik/fastapi-devops"
IMAGE_TAG="latest"

docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .

# If using Kind, load image into cluster
if command -v kind &> /dev/null && kind get clusters 2>/dev/null | grep -q .; then
    print_info "Kind detected, loading image into cluster..."
    kind load docker-image ${IMAGE_NAME}:${IMAGE_TAG}
fi

# =============================================================================
# Step 7: Deploy Application to All Environments
# =============================================================================
print_step "Deploying FastAPI to dev namespace..."
kubectl apply -k k8s/overlays/dev/

print_step "Deploying FastAPI to stage namespace..."
kubectl apply -k k8s/overlays/stage/

print_step "Deploying FastAPI to prod namespace..."
kubectl apply -k k8s/overlays/prod/

# =============================================================================
# Step 8: Wait for deployments
# =============================================================================
print_step "Waiting for deployments to be ready..."

echo "Dev environment..."
kubectl wait --for=condition=available deployment/dev-fastapi -n dev --timeout=120s || true

echo "Stage environment..."
kubectl wait --for=condition=available deployment/stage-fastapi -n stage --timeout=120s || true

echo "Prod environment..."
kubectl wait --for=condition=available deployment/prod-fastapi -n prod --timeout=120s || true

# =============================================================================
# Step 9: Display Status
# =============================================================================
echo ""
echo "=============================================="
echo "  Deployment Complete!"
echo "=============================================="
echo ""

print_step "Cluster Status:"
kubectl get nodes
echo ""

print_step "All Pods:"
kubectl get pods -A | grep -E "(NAME|fastapi|prometheus|envoy|metrics)"
echo ""

print_step "Services:"
kubectl get svc -A | grep -E "(NAME|fastapi|prometheus|envoy)"
echo ""

print_step "HPA Status (prod):"
kubectl get hpa -n prod
echo ""

echo "=============================================="
echo "  Access Information"
echo "=============================================="
echo ""
echo "Prometheus UI:"
echo "  kubectl port-forward -n monitoring svc/prometheus 9090:9090"
echo "  Then open: http://localhost:9090"
echo ""
echo "FastAPI (dev):"
echo "  kubectl port-forward -n dev svc/dev-fastapi 8001:8000"
echo "  Then open: http://localhost:8001"
echo ""
echo "FastAPI (stage):"
echo "  kubectl port-forward -n stage svc/stage-fastapi 8002:8000"
echo "  Then open: http://localhost:8002"
echo ""
echo "FastAPI (prod):"
echo "  kubectl port-forward -n prod svc/prod-fastapi 8003:8000"
echo "  Then open: http://localhost:8003"
echo ""
echo "=============================================="



