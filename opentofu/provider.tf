terraform {
  required_version = ">= 1.6"

  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

# No cloud provider required - using pre-provisioned VMs
# SSH access is used for remote provisioning
