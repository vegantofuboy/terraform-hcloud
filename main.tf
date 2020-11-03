// API Token Hetzner Cloud
variable "hcloud_token" {}

// Configure the Hetzner Cloud Provider
provider "hcloud" {
  token = var.hcloud_token
}
// Create a new SSH key
resource "hcloud_ssh_key" "default" {
  name       = "Terraform"
  public_key = file(var.public_key)
}

// Network configuration
resource "hcloud_network" "network" {
  name     = "network"
  ip_range = "10.10.0.0/16"
}

resource "hcloud_network_subnet" "sub" {
  network_id   = hcloud_network.network.id
  type         = "server"
  network_zone = "eu-central"
  ip_range     = "10.10.1.0/24"
}

resource "hcloud_network_route" "route" {
  destination = "10.100.1.0/24"
  gateway     = "10.10.1.1"
  network_id  = hcloud_network.network.id
}

// Create a Master
resource "hcloud_server" "master" {
  count       = var.master_count
  name        = format("%s-%03d", var.server_name_master, count.index + 1)
  image       = var.image
  server_type = var.server_type
  ssh_keys    = [hcloud_ssh_key.default.name]
  connection {
    private_key = file(var.private_key)
    user        = var.ansible_user
    host        = self.ipv4_address
  }

  provisioner "remote-exec" {
    inline = [
      "apt update -y && apt upgrade -y",
      "sudo apt-get -qq install python3 -y"
    ]
  }

  provisioner "local-exec" {
    command = <<EOT
    sleep 30;
  >hcloud.ini;
  echo "[hcolud]" | tee -a hcloud.ini;
  echo "${self.ipv4_address} ansible_user=${var.ansible_user} ansible_ssh_private_key_file=${var.private_key}" | tee -a hcloud.ini;
    export ANSIBLE_HOST_KEY_CHECKING=False;
  ansible-playbook -u ${var.ansible_user} --private-key ${var.private_key} -i hcloud.ini ../ansible/ansible-role-baseline.yml
  EOT
  }
}

// Create a Node
resource "hcloud_server" "node" {
  count       = var.node_count
  name        = format("%s-%03d", var.server_name_node, count.index + 1)
  image       = var.image
  server_type = var.server_type
  ssh_keys    = [hcloud_ssh_key.default.name]
  connection {
    private_key = file(var.private_key)
    user        = var.ansible_user
    host        = self.ipv4_address
  }

  provisioner "remote-exec" {
    inline = [
      "apt update -y && apt upgrade -y",
      "sudo apt-get -qq install python3 -y"
    ]
  }

  provisioner "local-exec" {
    command = <<EOT
    sleep 30;
  >hcloud.ini;
  echo "[hcolud]" | tee -a hcloud.ini;
  echo "${self.ipv4_address} ansible_user=${var.ansible_user} ansible_ssh_private_key_file=${var.private_key}" | tee -a hcloud.ini;
    export ANSIBLE_HOST_KEY_CHECKING=False;
  ansible-playbook -u ${var.ansible_user} --private-key ${var.private_key} -i hcloud.ini ../ansible/ansible-role-baseline.yml
  EOT
  }
}

resource "hcloud_server_network" "network_master" {
  count      = var.master_count
  server_id  = element(hcloud_server.master.*.id, count.index)
  network_id = hcloud_network.network.id
  ip         = cidrhost(hcloud_network_subnet.sub.ip_range, count.index + 2)
}
resource "hcloud_server_network" "network_node" {
  count      = var.node_count
  server_id  = element(hcloud_server.node.*.id, count.index)
  network_id = hcloud_network.network.id
  ip         = cidrhost(hcloud_network_subnet.sub.ip_range, count.index + 10)
}

// The Ansible inventoryfile
resource "local_file" "AnsibleInventory" {
  content = templatefile("inventory.tmpl",
    {
      addrs-master = hcloud_server.master.*.ipv4_address,
      addrs-node   = hcloud_server.node.*.ipv4_address
  })
  filename = "hcloud.ini"
}