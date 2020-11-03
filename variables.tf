// Public Key
variable "public_key" {
  default = "~/.ssh/hcloud.pub"
}

// Private Key
variable "private_key" {
  default = "~/.ssh/hcloud"
}

// Ansible User 
variable "ansible_user" {
  default = "root"
}

// Host Name / Host Name Mster
variable "server_name_master" {
  type    = string
  default = "vm-ma"
}

// Host Name / Host Name Mster
variable "server_name_node" {
  type    = string
  default = "vm-no"
}

// VM Size
variable "server_type" {
  type    = string
  default = "cx11"
}

// VM Image (Ubuntu images only)
variable "image" {
  type    = string
  default = "ubuntu-20.04"
}

// Number of Master you want to provision
variable "master_count" {
  type    = string
  default = "1"
}

// Number of nodes you want to provision
variable "node_count" {
  type    = string
  default = "2"
}