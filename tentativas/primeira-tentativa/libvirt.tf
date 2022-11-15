terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
    }
  }
}

# Add provider
provider "libvirt" {
  uri = "qemu:///system"
}

# Create pool
resource "libvirt_pool" "ubuntu" {
  name = "ubuntu_pool"
  type = "dir"
  path = "/libvirt_images/ubuntu-pool/"
}

# Create image
resource "libvirt_volume" "image-qcow2" {
  name = "ubuntu-amd64.qcow2"
  pool = libvirt_pool.ubuntu.name
  source = "${path.module}/downloads/ubuntu-22.04.1-live-server-amd64.iso"
  format = "qcow2"
}

# Add cloudinit disk to pool
resource "libvirt_cloudinit_disk" "commoninit" {
  name = "commoninit.iso"
  pool = libvirt_pool.ubuntu.name
  user_data = data.template_file.user_data.rendered
}

# Read the configuration
data "template_file" "user_data" {
  template = file("${path.module}/cloud_init.cfg")
}

# Define KVM domain to create
resource "libvirt_domain" "test-domain" {
  name = "test-vm-ubuntu"
  memory = "1024"
  vcpu = "1"
  
  cloudinit = libvirt_cloudinit_disk.commoninit.id
  
  network_interface {
    network_name = "default"
  }

  console {
    type = "pty"
    target_type = "serial"
    target_port = "0"
  }

  disk {
    volume_id = libvirt_volume.image-qcow2.id
  }

  graphics {
    type = "spice"
    listen_type = "address"
    autoport = true
  }
}


