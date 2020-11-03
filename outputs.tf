output "ip-master" {
  value = hcloud_server.master.*.ipv4_address
}

output "ip-node" {
  value = hcloud_server.node.*.ipv4_address
}