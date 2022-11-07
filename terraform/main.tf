terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "2.19.0"
    }
  }
}


provider "digitalocean" {
    token = var.do_token
}


data "digitalocean_ssh_key" "ssh_key" {
  name = "dopensource-training"
}


resource "digitalocean_droplet" "primary-kamailio" {
        name = "${var.primary-kamailio-dropletname}${count.index}"
        count = "${var.number_of_primary_environments}"
        region = "nyc1"
        size="s-1vcpu-1gb"
        image="debian-11-x64"
	      ssh_keys = [ "${data.digitalocean_ssh_key.ssh_key.fingerprint}" ]

        connection {
          host = self.ipv4_address
          user = "root"
          type = "ssh"
          private_key = "${file(var.pvt_key)}"
          timeout = "5m"
        }

        provisioner "remote-exec" {
          inline = [
          "export PATH=$PATH:/usr/bin",
          # install git repo and and server up the index page
          "sudo mkdir -p ~/bits/kamailio",
          "sudo apt-get update; sudo apt-get install -y git sngrep gcc g++ pkg-config libxml2-dev libssl-dev libcurl4-openssl-dev libpcre3-dev flex bison make autoconf  postgresql libpq5 libpq-dev",
          "sleep 20",
          "cd ~/bits",
          "git clone --depth 1 --no-single-branch https://github.com/kamailio/kamailio -b 5.5 kamailio",
          "cd ~/;git clone ${var.training-repo}",
          "sleep 20",
          "sed -i 's/\"set background=dark/set background=dark/' /etc/vim/vimrc"
        ]

      }
}

resource "digitalocean_droplet" "secondary-kamailio" {
        name = "${var.secondary-kamailio-dropletname}${count.index}"
        count = "${var.number_of_secondary_environments}"
        region = "nyc1"
        size="s-1vcpu-1gb"
        image="debian-11-x64"
	      ssh_keys = [ "${data.digitalocean_ssh_key.ssh_key.fingerprint}" ]

        connection {
          host = self.ipv4_address
          user = "root"
          type = "ssh"
          private_key = "${file(var.pvt_key)}"
          timeout = "5m"
        }

        provisioner "remote-exec" {
          inline = [
          "export PATH=$PATH:/usr/bin",
          # install git repo and and server up the index page
          "sudo mkdir -p ~/bits/kamailio",
          "sudo apt-get update; sudo apt-get install -y git sngrep gcc g++ pkg-config libxml2-dev libssl-dev libcurl4-openssl-dev libpcre3-dev flex bison make autoconf  postgresql libpq5 libpq-dev",
          "sleep 20",
          "cd ~/bits",
          "git clone --depth 1 --no-single-branch https://github.com/kamailio/kamailio -b 5.5 kamailio",
          "cd ~/;git clone ${var.training-repo}",
          "sleep 20",
          "sed -i 's/\"set background=dark/set background=dark/' /etc/vim/vimrc"
        ]

      }
}

resource "digitalocean_droplet" "fusionpbx" {
        name = "${var.fusionpbx-dropletname}${count.index}"
        count = "${var.number_of_primary_environments}"
        region = "nyc1"
        size="s-1vcpu-1gb"
        image="debian-10-x64"
	      ssh_keys = [ "${data.digitalocean_ssh_key.ssh_key.fingerprint}" ]

        connection {
          host = self.ipv4_address
          user = "root"
          type = "ssh"
          private_key = "${file(var.pvt_key)}"
          timeout = "15m"
        }

        provisioner "remote-exec" {
          inline = [
          "export PATH=$PATH:/usr/bin",
           # Setup VIM
          "sed -i 's/\"set background=dark/set background=dark/' /etc/vim/vimrc",
           # install FusionPBX
          "wget -O - https://raw.githubusercontent.com/fusionpbx/fusionpbx-install.sh/master/debian/pre-install.sh | sh; cd /usr/src/fusionpbx-install.sh/debian && ./install.sh",
          "sleep 20"
        ]
      }
}


resource "digitalocean_record" "pkam" {
   
  count = "${var.number_of_primary_environments}"
  domain = "dopensource.net"
  type = "A"
  name = digitalocean_droplet.primary-kamailio.*.name[count.index]
  value = digitalocean_droplet.primary-kamailio.*.ipv4_address[count.index]
}

resource "digitalocean_record" "skam" {
   
  count = "${var.number_of_secondary_environments}"
  domain = "dopensource.net"
  type = "A"
  name = digitalocean_droplet.secondary-kamailio.*.name[count.index]
  value = digitalocean_droplet.secondary-kamailio.*.ipv4_address[count.index]
}

resource "digitalocean_record" "fusionpbx-A-record" {
  count = var.number_of_shared_environments
  domain = "dopensource.net"
  type = "A"
  name =  digitalocean_droplet.fusionpbx.*.name[count.index]
  value = digitalocean_droplet.fusionpbx.*.ipv4_address[count.index]
}
