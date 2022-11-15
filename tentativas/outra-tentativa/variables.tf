variable "MEMORY_SIZE" {
    default = "1024"
    type = string  
}
variable "VCPU_SIZE" {
    default = 1
    type = number
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
    default = "vm-test"
    type = string
}

variable "VM_IMG_URL" {
    default = "https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img"
    type = string
}
variable "VM_VOLUME_SIZE" {
    default = 1024*1024*1024*5
type = number
}

variable "VM_IMG_FORMAT" {
    default = "qcow2"
    type = string
}

variable "VM_CIDR_RANGE" {
    default = "192.168.1.0/24"
    type = string
}
