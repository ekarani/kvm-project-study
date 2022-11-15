terraform {
    required_providers{
        libvirt = {
            source = "dmacvicar/libvirt"
            version = "0.6.14"
        }
    }
}

provider "libvirt" {
    uri = "qemu:///system"
    ## Configuration options
    #alias = "server2"
    
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

resource "libvirt_pool" "vm" {
    name = "${var.VM_HOSTNAME}_pool"
    type = "dir" 
    path = "/images_kvm/terraform-provider-libvirt-pool-ubuntu"
    
}

resource "libvirt_volume" "base_ubuntu_qcow2" {
    name = "${var.VM_HOSTNAME}-base_volume.${var.VM_IMG_FORMAT}"
    pool = libvirt_pool.vm.name
    source = var.VM_IMG_URL
    format = var.VM_IMG_FORMAT
}

resource "libvirt_volume" "vm" {
    count = var.VM_COUNT
    name = "${var.VM_HOSTNAME}-${count.index}_volume.${var.VM_IMG_FORMAT}"
    pool = libvirt_pool.vm.name
    format = var.VM_IMG_FORMAT
    size = var.VM_VOLUME_SIZE
    base_volume_id = libvirt_volume.base_ubuntu_qcow2.id
}


resource "libvirt_network" "vm_public_network" {
    name = "${var.VM_HOSTNAME}_network"
    #autostart = true
    mode = "nat"
    #bridge = "br0"
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
    name           = "${var.VM_HOSTNAME}_cloudinit.iso"
    user_data       = data.template_file.user_data.rendered
    network_config  = data.template_file.network_config.rendered
    pool            = libvirt_pool.vm.name
  
}

resource "random_string" "vm-name" {
  length = 6
  upper  = false
  number = false
  lower  = true
  special = false
}

resource "libvirt_domain" "vm" {
    count = var.VM_COUNT
    name   = "${var.VM_HOSTNAME}-${count.index}-${random_string.vm-name.result}"
    memory = var.MEMORY_SIZE
    vcpu = var.VCPU_SIZE

    cloudinit = "${libvirt_cloudinit_disk.cloudinit.id}"  

    qemu_agent = true

    autostart = true
    
    network_interface {
        hostname = var.VM_HOSTNAME
        network_name= "${libvirt_network.vm_public_network.name}"
        network_id = "${libvirt_network.vm_public_network.id}"
        
    }
    console {
        type = "pty"       
        target_type = "serial"
        target_port = "0"
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
output "IPS" {
    value = "${libvirt_domain.vm.*.network_interface.0.addresses}"
  
}
