output "control_plane_external_ip" {
  description = "External IP address of the Kubernetes control plane node"
  value       = var.vm_external_ips[0]
}

output "control_plane_internal_ip" {
  description = "Internal IP address of the Kubernetes control plane node"
  value       = var.vm_internal_ips[0]
}

output "worker_node_external_ips" {
  description = "External IP addresses of Kubernetes worker nodes"
  value       = slice(var.vm_external_ips, 1, length(var.vm_external_ips))
}

output "worker_node_internal_ips" {
  description = "Internal IP addresses of Kubernetes worker nodes"
  value       = slice(var.vm_internal_ips, 1, length(var.vm_internal_ips))
}

output "ssh_connection_command" {
  description = "SSH command to connect to the control plane"
  value       = "ssh -i ${var.ssh_key} ${var.ssh_user}@${var.vm_external_ips[0]}"
  sensitive   = true
}

output "cluster_info" {
  description = "Cluster configuration summary"
  value = {
    control_plane_external = var.vm_external_ips[0]
    control_plane_internal = var.vm_internal_ips[0]
    workers_external       = slice(var.vm_external_ips, 1, length(var.vm_external_ips))
    workers_internal       = slice(var.vm_internal_ips, 1, length(var.vm_internal_ips))
    total_nodes            = length(var.vm_external_ips)
    ssh_user               = var.ssh_user
  }
}
