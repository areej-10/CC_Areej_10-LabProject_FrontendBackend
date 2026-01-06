variable "vpc_cidr_block" { default = "10.0.0.0/16" }
variable "subnet_cidr_block" { default = "10.0.10.0/24" }
variable "avail_zone" { default = "us-east-1a" }
variable "env_prefix" { default = "lab-project" }
variable "instance_type" { default = "t3.micro" }
variable "ssh_key_name" { default = "id_ed25519" }

# This variable is used by the inventory template to tell Ansible where the key is
variable "private_key_path" {
  default = "~/.ssh/id_ed25519"
}

# These two match the 'undeclared variable' warnings from your screenshot
variable "private_key_location" {
  description = "Path to private SSH key used in .tfvars"
}

variable "public_key_location" {
  description = "Path to public SSH key used in .tfvars"
}