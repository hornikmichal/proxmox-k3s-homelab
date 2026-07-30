# Centralized definition of all cluster nodes
locals {
  servers = {
    "bastion-node"  = { ip = "10.0.0.50", cores = 2, memory = 1024, disk = 20 }
    "k8s-master-1"  = { ip = "10.0.0.61", cores = 2, memory = 2048, disk = 30 }
    "k8s-master-2"  = { ip = "10.0.0.62", cores = 2, memory = 2048, disk = 30 }
    "k8s-master-3"  = { ip = "10.0.0.63", cores = 2, memory = 2048, disk = 30 }
    "k8s-worker-1"  = { ip = "10.0.0.71", cores = 4, memory = 4096, disk = 50 }
    "k8s-worker-2"  = { ip = "10.0.0.72", cores = 4, memory = 4096, disk = 50 }
    "docker-single" = { ip = "10.0.0.81", cores = 2, memory = 4096, disk = 40 }
    "mail-server"   = { ip = "10.0.0.82", cores = 2, memory = 8192, disk = 60 }
  }
}

# Universal resource block iterating over the servers map
resource "proxmox_virtual_environment_vm" "nodes" {
  for_each    = local.servers

  name        = each.key
  node_name   = var.proxmox_node_name
  description = "Managed by Terraform"
  tags        = ["terraform", "homelab", "k8s"]

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
}