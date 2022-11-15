terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
      version = "0.6.14"
    }
  }
}

variable "VM_COUNT" {
  default = 1
  type = number
}

variable "VM_USER" {
  default = "ubuntu"
  type = string
}

variable "VM_HOSTNAME" {
  default = "vm"
  type = string
}

variable "VM_IMG_URL" {
  default = "https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img"
#  default = "https://releases.ubuntu.com/22.04.1/ubuntu-22.04.1-live-server-amd64.iso?_ga=2.219054288.874291698.1668433534-1060412402.1667931471"
  type = string
}

variable "VM_IMG_FORMAT" {
  default = "qcow2"
  type = string
}

variable "VM_CIDR_RANGE" {
  default = "10.10.10.10/24"
  type = string
}

# Instance the provider
provider "libvirt" {
  uri = "qemu:///system"
}

data "template_file" "user_data" {
  template = file("${path.module}/cloud_init.cfg")
  vars = {
    VM_USER = var.VM_USER
  }
}

data "template_file" "network_config" {
  template = file("${path.module}/network_config.cfg")
}

# Define resources

resource "libvirt_pool" "vm" {
  name = "${var.VM_HOSTNAME}_pool"
  type = "dir"
  path = "/tmp/terraform-provider-libvirt-pool-ubuntu"
}

resource "libvirt_volume" "vm" {
  count = var.VM_COUNT
  name = "${var.VM_HOSTNAME}-${count.index}_volume.${var.VM_IMG_FORMAT}"
  pool = libvirt_pool.vm.name
  source = var.VM_IMG_URL
  format = var.VM_IMG_FORMAT
}

resource "libvirt_network" "vm_public_network" {
  name = "${var.VM_HOSTNAME}_network"
  mode = "nat"
  domain = "${var.VM_HOSTNAME}.local"
  addresses = ["${var.VM_CIDR_RANGE}"]
  dhcp {
    enabled = true
  }
  dns {
    enabled = true
  }
}

resource "libvirt_cloudinit_disk" "cloudinit" {
  name = "${var.VM_HOSTNAME}_cloudinit.iso"
  user_data = data.template_file.user_data.rendered
  network_config = data.template_file.network_config.rendered
  pool = libvirt_pool.vm.name
}

resource "libvirt_domain" "vm" {
  count = var.VM_COUNT
  name = "${var.VM_HOSTNAME}-${count.index}"
  memory = "1024"
  vcpu = 1
  
  cloudinit = "${libvirt_cloudinit_disk.cloudinit.id}"
  
  network_interface {
    network_id = "${libvirt_network.vm_public_network.id}"
    network_name = "${libvirt_network.vm_public_network.name}"
  }

  console {
    type = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
    type = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  disk {
    volume_id = "${libvirt_volume.vm[count.index].id}"
  }
  
  graphics {
    type = "spice"
    listen_type = "address"
    autoport = true
  }

}

  
