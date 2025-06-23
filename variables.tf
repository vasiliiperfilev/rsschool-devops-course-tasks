variable "account_id" {
  description = "AWS account ID"
  type        = string
}

variable "repo_owner" {
  description = "Github repository owner"
  type        = string
}

variable "repo_name" {
  description = "Github repository name"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR Block for VPC"
  default     = "10.0.0.0/16"
}
variable "public_subnet_1_cidr" {
  description = "CIDR Block for Public Subnet 1"
  default     = "10.0.1.0/24"
}
variable "public_subnet_2_cidr" {
  description = "CIDR Block for Public Subnet 2"
  default     = "10.0.2.0/24"
}
variable "private_subnet_1_cidr" {
  description = "CIDR Block for Private Subnet 1"
  default     = "10.0.3.0/24"
}
variable "private_subnet_2_cidr" {
  description = "CIDR Block for Private Subnet 2"
  default     = "10.0.4.0/24"
}

variable "allowed_ssh_cidr" {
  description = "Allowed SSH CIDR"
  type        = string
  default     = "0.0.0.0/0"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "amis" {
  description = "Which AMI to spawn."
  type        = map(string)
  default = {
    us-east-2 = "ami-0568773882d492fc8"
    us-east-1 = "ami-05fa00d4c63e32376"
  }
}

variable "ssh_bastion_pubkey_name" {
  description = "SSH public key name"
  type        = string
  default     = "bastion_key_pair"
}
