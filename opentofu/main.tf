# =============================================================================
# OpenTofu Configuration for Kubernetes Cluster Bootstrap
# =============================================================================
# This configuration provisions a complete Kubernetes cluster:
# - Installs container runtime (containerd) on all nodes
# - Installs Kubernetes components (kubelet, kubeadm, kubectl)
# - Initializes control plane with kubeadm
# - Installs Flannel CNI for pod networking
# - Joins worker nodes to the cluster
# =============================================================================

locals {
  common_packages = [
    "curl",
    "ca-certificates",
    "gnupg",
    "apt-transport-https",
    "software-properties-common"
  ]

  # External IPs for SSH access
  control_plane_external_ip = var.vm_external_ips[0]
  worker_external_ips       = slice(var.vm_external_ips, 1, length(var.vm_external_ips))

  # Internal IPs for Kubernetes cluster (used by kubeadm)
  control_plane_internal_ip = var.vm_internal_ips[0]
  worker_internal_ips       = slice(var.vm_internal_ips, 1, length(var.vm_internal_ips))
}

# =============================================================================
# Step 1: Bootstrap All Nodes (Install containerd + Kubernetes components)
# =============================================================================
resource "null_resource" "k8s_bootstrap" {
  count = length(var.vm_external_ips)

  connection {
    type        = "ssh"
    host        = var.vm_external_ips[count.index]
    user        = var.ssh_user
    private_key = file(var.ssh_key)
    timeout     = "10m"
  }

  provisioner "remote-exec" {
    inline = [
      "echo '>>> [Node ${count.index}] Updating system packages...'",
      "sudo apt update -y",
      "sudo apt install -y ${join(" ", local.common_packages)}",

      # Disable swap (required for Kubernetes)
      "echo '>>> Disabling swap...'",
      "sudo swapoff -a",
      "sudo sed -i '/ swap / s/^/#/' /etc/fstab",

      # Load required kernel modules
      "echo '>>> Loading kernel modules...'",
      "sudo modprobe overlay",
      "sudo modprobe br_netfilter",
      "echo 'overlay' | sudo tee /etc/modules-load.d/k8s.conf",
      "echo 'br_netfilter' | sudo tee -a /etc/modules-load.d/k8s.conf",

      # Configure sysctl for Kubernetes networking
      "echo '>>> Configuring sysctl...'",
      "cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf",
      "net.bridge.bridge-nf-call-iptables=1",
      "net.bridge.bridge-nf-call-ip6tables=1",
      "net.ipv4.ip_forward=1",
      "EOF",
      "sudo sysctl --system",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "echo '>>> Installing containerd...'",
      "sudo apt install -y containerd",
      "sudo mkdir -p /etc/containerd",
      "sudo containerd config default | sudo tee /etc/containerd/config.toml",
      "sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml",
      "sudo systemctl restart containerd",
      "sudo systemctl enable containerd",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "echo '>>> Installing Kubernetes components...'",
      "sudo mkdir -p /etc/apt/keyrings",
      "curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/k8s.gpg --yes",
      "echo 'deb [signed-by=/etc/apt/keyrings/k8s.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/k8s.list",
      "sudo apt update -y",
      "sudo apt install -y kubelet kubeadm kubectl",
      "sudo apt-mark hold kubelet kubeadm kubectl",
      "sudo systemctl enable kubelet",
      "echo '>>> Node ${count.index} bootstrap complete!'",
    ]
  }

  triggers = {
    always_run = timestamp()
  }
}

# =============================================================================
# Step 2: Reset any previous cluster state (cleanup)
# =============================================================================
resource "null_resource" "cluster_reset" {
  count      = length(var.vm_external_ips)
  depends_on = [null_resource.k8s_bootstrap]

  connection {
    type        = "ssh"
    host        = var.vm_external_ips[count.index]
    user        = var.ssh_user
    private_key = file(var.ssh_key)
    timeout     = "5m"
  }

  provisioner "remote-exec" {
    inline = [
      "echo '>>> Resetting any existing cluster state...'",
      "sudo kubeadm reset -f || true",
      "sudo rm -rf /etc/cni/net.d/* || true",
      "sudo rm -rf ~/.kube || true",
      "sudo iptables -F && sudo iptables -t nat -F && sudo iptables -t mangle -F && sudo iptables -X || true",
      "sudo rm -rf /var/lib/etcd || true",
      "echo '>>> Reset complete'",
    ]
  }

  triggers = {
    always_run = timestamp()
  }
}

# =============================================================================
# Step 3: Initialize Control Plane (using INTERNAL IP)
# =============================================================================
resource "null_resource" "control_plane_init" {
  depends_on = [null_resource.cluster_reset]

  connection {
    type        = "ssh"
    host        = local.control_plane_external_ip
    user        = var.ssh_user
    private_key = file(var.ssh_key)
    timeout     = "15m"
  }

  provisioner "remote-exec" {
    inline = [
      "echo '>>> Initializing Kubernetes Control Plane with internal IP ${local.control_plane_internal_ip}...'",

      # Initialize cluster using INTERNAL IP (important for cloud VMs with NAT)
      "sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=${local.control_plane_internal_ip} --v=5 2>&1 | tee /tmp/kubeadm-init.log",

      # Wait for API server
      "echo '>>> Waiting for API server to start...'",
      "sleep 30",

      # Setup kubeconfig for user
      "mkdir -p $HOME/.kube",
      "sudo cp -f /etc/kubernetes/admin.conf $HOME/.kube/config",
      "sudo chown $(id -u):$(id -g) $HOME/.kube/config",

      # Verify API server is running
      "echo '>>> Verifying control plane...'",
      "kubectl get nodes || echo 'Waiting for API server...'",
      "sleep 10",

      # Install Flannel CNI
      "echo '>>> Installing Flannel CNI...'",
      "kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml",

      # Wait for control plane to be ready
      "echo '>>> Waiting for control plane to stabilize...'",
      "sleep 60",
      "kubectl get nodes",
      "kubectl get pods -n kube-system",

      "echo '>>> Control plane initialization complete!'",
    ]
  }

  triggers = {
    always_run = timestamp()
  }
}

# =============================================================================
# Step 4: Join Worker Nodes
# =============================================================================
resource "null_resource" "worker_join" {
  count      = length(local.worker_external_ips)
  depends_on = [null_resource.control_plane_init]

  # Get join command from control plane
  provisioner "local-exec" {
    command = <<-EOT
      ssh -o StrictHostKeyChecking=no -i ${var.ssh_key} ${var.ssh_user}@${local.control_plane_external_ip} \
        "kubeadm token create --print-join-command" > /tmp/join-command-${count.index}.sh
    EOT
  }

  connection {
    type        = "ssh"
    host        = local.worker_external_ips[count.index]
    user        = var.ssh_user
    private_key = file(var.ssh_key)
    timeout     = "10m"
  }

  provisioner "file" {
    source      = "/tmp/join-command-${count.index}.sh"
    destination = "/tmp/join-command.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "echo '>>> Joining worker node ${count.index + 1} to cluster...'",
      "chmod +x /tmp/join-command.sh",
      "sudo /tmp/join-command.sh",
      "echo '>>> Worker node ${count.index + 1} joined successfully!'",
    ]
  }

  triggers = {
    always_run = timestamp()
  }
}

# =============================================================================
# Step 5: Verify Cluster and Deploy Base Components
# =============================================================================
resource "null_resource" "cluster_verify" {
  depends_on = [null_resource.worker_join]

  connection {
    type        = "ssh"
    host        = local.control_plane_external_ip
    user        = var.ssh_user
    private_key = file(var.ssh_key)
    timeout     = "10m"
  }

  provisioner "remote-exec" {
    inline = [
      "echo '>>> Waiting for all nodes to be Ready...'",
      "sleep 60",

      # Verify cluster status
      "echo '=== CLUSTER STATUS ==='",
      "kubectl get nodes -o wide",
      "echo ''",
      "kubectl get pods -n kube-system",

      # Create namespaces for environments
      "echo '>>> Creating namespaces...'",
      "kubectl create namespace dev --dry-run=client -o yaml | kubectl apply -f -",
      "kubectl create namespace stage --dry-run=client -o yaml | kubectl apply -f -",
      "kubectl create namespace prod --dry-run=client -o yaml | kubectl apply -f -",

      "echo ''",
      "echo '=== KUBERNETES CLUSTER READY ==='",
      "kubectl get namespaces",
    ]
  }

  triggers = {
    always_run = timestamp()
  }
}
