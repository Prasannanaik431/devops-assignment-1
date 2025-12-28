#!/bin/bash
# =============================================================================
# Kubernetes Cluster Setup Script
# =============================================================================
# This script runs on the CONTROL PLANE node after OpenTofu provisioning.
# Prerequisites: SSH access to control plane node
# =============================================================================

set -e

echo "=============================================="
echo "  Kubernetes Cluster Initialization Script"
echo "=============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_step() {
    echo -e "${GREEN}[STEP]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then
    print_error "Please run as root or with sudo"
    exit 1
fi

# =============================================================================
# Step 1: Initialize Kubernetes Cluster
# =============================================================================
print_step "Initializing Kubernetes cluster with kubeadm..."

kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=$(hostname -I | awk '{print $1}')

# =============================================================================
# Step 2: Configure kubectl for the current user
# =============================================================================
print_step "Configuring kubectl..."

SUDO_USER_HOME=$(getent passwd $SUDO_USER | cut -d: -f6)
mkdir -p $SUDO_USER_HOME/.kube
cp -i /etc/kubernetes/admin.conf $SUDO_USER_HOME/.kube/config
chown $(id -u $SUDO_USER):$(id -g $SUDO_USER) $SUDO_USER_HOME/.kube/config

# Also set up for root
mkdir -p /root/.kube
cp -i /etc/kubernetes/admin.conf /root/.kube/config

export KUBECONFIG=/etc/kubernetes/admin.conf

# =============================================================================
# Step 3: Install Calico CNI
# =============================================================================
print_step "Installing Calico CNI for pod networking..."

kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/calico.yaml

echo "Waiting for Calico to be ready..."
sleep 30
kubectl wait --for=condition=ready pods -l k8s-app=calico-node -n kube-system --timeout=300s || true

# =============================================================================
# Step 4: Generate join command for workers
# =============================================================================
print_step "Generating join command for worker nodes..."

JOIN_COMMAND=$(kubeadm token create --print-join-command)
echo ""
echo "=============================================="
echo "  WORKER NODE JOIN COMMAND"
echo "=============================================="
echo ""
echo "Run this command on each worker node:"
echo ""
echo "sudo $JOIN_COMMAND"
echo ""
echo "=============================================="

# Save join command to a file
echo "$JOIN_COMMAND" > /tmp/kubeadm-join-command.txt
print_step "Join command saved to /tmp/kubeadm-join-command.txt"

# =============================================================================
# Step 5: Verify cluster status
# =============================================================================
print_step "Verifying cluster status..."

echo ""
kubectl get nodes
echo ""

print_step "Cluster initialization complete!"
echo ""
echo "Next steps:"
echo "1. Run the join command on each worker node"
echo "2. Wait for workers to join: kubectl get nodes"
echo "3. Deploy the application stack"



