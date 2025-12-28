#!/bin/bash
# =============================================================================
# Script to get kubeconfig for CI/CD pipeline
# =============================================================================
# This script retrieves the kubeconfig from the control plane and outputs
# it in base64 format for use as a GitHub Actions secret.
#
# Usage: ./scripts/get-kubeconfig.sh
#
# The output can be used as the KUBECONFIG secret in GitHub Actions.
# =============================================================================

set -e

# Configuration
CONTROL_PLANE_IP="${CONTROL_PLANE_IP:-34.14.169.168}"
SSH_USER="${SSH_USER:-prasanna}"
SSH_KEY="${SSH_KEY:-~/.ssh/devops-assignment-prasanna}"

echo "Fetching kubeconfig from ${CONTROL_PLANE_IP}..."

# Get kubeconfig from control plane
ssh -o StrictHostKeyChecking=no -i "${SSH_KEY}" "${SSH_USER}@${CONTROL_PLANE_IP}" \
    "sudo cat /etc/kubernetes/admin.conf" > /tmp/kubeconfig.yaml

# Replace internal IP with external IP for remote access
sed -i.bak "s|https://10.160.0.3:6443|https://${CONTROL_PLANE_IP}:6443|g" /tmp/kubeconfig.yaml

echo ""
echo "=========================================="
echo "KUBECONFIG (base64 encoded for GitHub Actions secret):"
echo "=========================================="
cat /tmp/kubeconfig.yaml | base64

echo ""
echo "=========================================="
echo "Copy the above base64 string and add it as KUBECONFIG secret in GitHub"
echo "=========================================="

# Cleanup
rm -f /tmp/kubeconfig.yaml /tmp/kubeconfig.yaml.bak


