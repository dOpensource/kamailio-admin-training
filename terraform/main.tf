provider "digitalocean" {
    token = "${var.do_token}"
}


data "digitalocean_ssh_key" "ssh_key" {
  name = "dopensource-training"
}


resource "digitalocean_droplet" "kamailio-server" {
        name = "${var.dropletname}${count.index}"
        count = "${var.number_of_servers}"
        region = "nyc1"
        size="1gb"
        image="debian-9-x64"
	      ssh_keys = [ "${data.digitalocean_ssh_key.ssh_key.fingerprint}" ]

        connection {
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
          "sudo apt-get update; sudo apt-get install -y git sngrep gcc g++ pkg-config libxml2-dev libssl-dev libcurl4-openssl-dev libpcre3-dev flex bison default-libmysqlclient-dev make autoconf mariadb-server",
          "sleep 20",
          "cd ~/bits",
	  "git clone --depth 1 --no-single-branch https://github.com/kamailio/kamailio -b 5.3 kamailio",
	  "cd ~/;git clone https://github.com/dOpensource/kamailio-admin-training",
          "sleep 20",
          "sed -i 's/\"set background=dark/set background=dark/' /etc/vim/vimrc"
        ]

      }
}

resource "digitalocean_droplet" "fusionpbx" {
        name = "${var.fusionpbx-dropletname}${count.index}"
        count = "${var.number_of_servers}"
        region = "nyc1"
        size="1gb"
        image="debian-9-x64"
	      ssh_keys = [ "${data.digitalocean_ssh_key.ssh_key.fingerprint}" ]

        connection {
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


#resource "digitalocean_record" "A-staging" {
#   
#  count = "${var.number_of_servers}"
#  domain = "dopensource.net"
#  type = "A"
#  name = "${digitalocean_droplet.kamailio-server.name}"
#  value = "${digitalocean_droplet.kamailio-server.ipv4_address}"
#}

#resource "digitalocean_record" "fusionpbx-A-record" {
#  count = "${var.number_of_servers}"
#  domain = "dopensource.net"
#  type = "A"
#  name = "${digitalocean_droplet.fusionpbx.name}"
#  value = "${digitalocean_droplet.fusionpbx.ipv4_address}"
#}
