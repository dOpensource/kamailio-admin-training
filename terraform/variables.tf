# Digital Ocean Token 
variable "do_token" {
}

# Optional Prepfix for the workshop
variable "prefix" {
	default =""
}

# The private key being used to connect to the VM to provision them
variable "pvt_key" {
  default = "~/.ssh/dopensource-training"
}

# The name of the Kamailio Instances
variable "kamailio-dropletname" {
  default = "kamailio-lab-training"
}

# The name ofthe FusionPBX Instances
variable "fusionpbx-dropletname" {
  default = "fusionpbx-lab-training"
}

# The Number of Environments to Deploy
variable "number_of_environments" {
  default = "1"
}

# The domainname to use when setting up DNS
variable "domainname" {
  default = "dopensource.net"
}

# The name of the GIT repo that contains the labs
# By default, the labs are in the same repo as this Terraform script
# But, doesn't have to be
variable "training-repo" {
	default="https://github.com/dOpensource/kamailio-admin-training.git"
}

