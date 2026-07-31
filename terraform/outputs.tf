# Output the assigned IP addresses for easy access after deployment
output "vm_ips" {
  description = "IP addresses of the provisioned virtual machines"
  value = {
    for name, vm in proxmox_virtual_environment_vm.nodes : name => vm.ipv4_addresses[1][0]
  }
}