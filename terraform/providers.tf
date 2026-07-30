# Configure the Proxmox provider
provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = var.proxmox_api_token
  # Insecure is set to true for homelab environment with self-signed certificates
  insecure  = var.proxmox_insecure 
}