variable "do_token" {
}

variable "prefix" {
	default =""
}

variable "pvt_key" {
  default = "~/.ssh/dopensource-training"
}

variable "dropletname" {
  default = "kamailio"
}

variable "fusionpbx-dropletname" {
  default = "fusionpbx"
}

variable "number_of_servers" {
  default = "1"
}

variable "domainname" {
  default = "dopensource.net"
}

variable "repo" {
	default="https://github.com/detroitblacktech/webportal.git"
}

variable "branch" {
	default="dev"
}
