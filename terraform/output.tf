output "kamailio-server-ssh" {
  value = "${digitalocean_droplet.kamailio-server.*.ipv4_address}"
}

output "fusionpbx-server-ssh" {
  value = "${digitalocean_droplet.fusionpbx.*.ipv4_address}"
}
