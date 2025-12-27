# =============================================================================
# Variables for Kubernetes Cluster Configuration
# =============================================================================

variable "vm_external_ips" {
  description = "External/Public IPs for SSH access"
  type        = list(string)
  default = [
    "34.14.169.168",  # Control Plane
    "34.100.156.67",  # Worker Node 1
    "34.14.213.230"   # Worker Node 2
  ]
}

variable "vm_internal_ips" {
  description = "Internal/Private IPs for Kubernetes cluster communication"
  type        = list(string)
  default = [
    "10.160.0.3",     # Control Plane
    "10.160.0.4",     # Worker Node 1
    "10.160.0.5"      # Worker Node 2
  ]
}

variable "ssh_user" {
  description = "SSH username for connecting to VMs"
  type        = string
  default     = "prasanna"
}

variable "ssh_key" {
  description = "Path to the SSH private key file"
  type        = string
  default     = "~/.ssh/devops-assignment-prasanna"
  sensitive   = true
}

# Legacy variable for backwards compatibility
variable "vm_ips" {
  description = "Deprecated: Use vm_external_ips instead"
  type        = list(string)
  default     = []
}
