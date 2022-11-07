output "primary-kamailio-server" {
  value = "${digitalocean_droplet.primary-kamailio.*.ipv4_address}"
}

output "secondary-kamailio-server" {
  value = "${digitalocean_droplet.secondary-kamailio.*.ipv4_address}"
}

output "fusionpbx" {
  value = "${digitalocean_droplet.fusionpbx.*.ipv4_address}"
}
