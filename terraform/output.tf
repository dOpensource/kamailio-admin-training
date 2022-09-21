output "kamailio-server-ssh" {
  value = "${digitalocean_droplet.kamailio-lab-training.*.ipv4_address}"
}

output "fusionpbx-server-ssh" {
  value = "${digitalocean_droplet.fusionpbx-lab-training.*.ipv4_address}"
}
