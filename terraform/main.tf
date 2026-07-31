# Centralized data-driven definition of all cluster nodes including specific tags
locals {
  servers = {
    "devops-terminal" = { ip = "10.217.97.40", cores = 2, memory = 2048, disk = 15, tags = ["terraform", "homelab", "admin"] }
    "bastion-node"    = { ip = "10.217.97.50", cores = 2, memory = 1024, disk = 10, tags = ["terraform", "homelab", "bastion"] }
    "k8s-master-1"    = { ip = "10.217.97.61", cores = 2, memory = 2048, disk = 15, tags = ["terraform", "homelab", "k3s"] }
    "k8s-master-2"    = { ip = "10.217.97.62", cores = 2, memory = 2048, disk = 15, tags = ["terraform", "homelab", "k3s"] }
    "k8s-master-3"    = { ip = "10.217.97.63", cores = 2, memory = 2048, disk = 15, tags = ["terraform", "homelab", "k3s"] }
    "k8s-worker-1"    = { ip = "10.217.97.71", cores = 4, memory = 4096, disk = 20, tags = ["terraform", "homelab", "k3s"] }
    "k8s-worker-2"    = { ip = "10.217.97.72", cores = 4, memory = 4096, disk = 20, tags = ["terraform", "homelab", "k3s"] }
    "docker-single"   = { ip = "10.217.97.81", cores = 2, memory = 4096, disk = 20, tags = ["terraform", "homelab", "docker"] }
    "mail-server"     = { ip = "10.217.97.82", cores = 2, memory = 8192, disk = 20, tags = ["terraform", "homelab", "docker", "mailserver"] }
  }
}

# Universal resource block iterating over the servers map
resource "proxmox_virtual_environment_vm" "nodes" {
  for_each    = local.servers

  name        = each.key
  node_name   = var.proxmox_node_name
  description = "Managed by Terraform"

# Dynamic tag assignment from the local map
  tags        = each.value.tags

  clone {
    vm_id = var.template_vm_id
    full  = true
  }

  agent {
    enabled = true
  }

  cpu {
    cores = each.value.cores
    type  = "host"
  }

  memory {
    dedicated = each.value.memory
  }

  disk {
    datastore_id = "local-lvm"
    size         = each.value.disk
    interface    = "scsi0"

# Explicitly defining performance parameters inherited from the template
    discard      = "on"
    iothread     = true
    ssd          = true

  }

# Explicit VGA configuration for headless server with serial console
vga {
    memory = 16
    type   = "serial0"
  }

  network_device {
    bridge  = var.network_config.bridge
    vlan_id = var.network_config.vlan_id
  }

  initialization {
    dns {
      servers = var.network_config.dns
    }
    ip_config {
      ipv4 {
        address = "${each.value.ip}/${var.network_config.cidr}"
        gateway = var.network_config.gateway
      }
    }
    user_account {
      username = var.vm_username
      keys     = [var.ssh_public_key]
    }
  }

# We only ignore the MAC address drift, as Proxmox generates a new one upon cloning
  lifecycle {
    ignore_changes = [
      network_device[0].mac_address
    ]
  }
}

# Generate Ansible inventory dynamically based on the local servers map
resource "local_file" "ansible_inventory" {
  filename = "inventory.ini"
  content = templatefile("inventory.tftpl", {
    # Filters IPs by checking if the server name contains "master" or "worker"
    master_ips = [for k, v in local.servers : v.ip if can(regex("master", k))]
    worker_ips = [for k, v in local.servers : v.ip if can(regex("worker", k))]
    user       = var.vm_username
  })
}