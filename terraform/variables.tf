# Input variables definition for maximum reusability
variable "proxmox_endpoint" {
  type        = string
  description = "Proxmox API endpoint URL"
}

variable "proxmox_api_token" {
  type        = string
  sensitive   = true
  description = "API token for Proxmox authentication"
}

variable "proxmox_insecure" {
  type        = bool
  default     = true
  description = "Allow insecure connections to Proxmox API"
}

variable "proxmox_node_name" {
  type        = string
  description = "Target Proxmox node name"
}

variable "template_vm_id" {
  type        = number
  description = "ID of the Cloud-Init VM template"
}

variable "network_config" {
  type = object({
    bridge  = string
    vlan_id = number
    gateway = string
    cidr    = number
    dns     = list(string)
  })
  description = "Network configuration map for the VMs"
}

variable "vm_username" {
  type        = string
  description = "Default username provisioned via Cloud-Init"
}

variable "ssh_public_key" {
  type        = string
  description = "SSH Ed25519 public key injected through Cloud-Init"
}