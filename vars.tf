variable "name" {
}

// cidr prefix
variable "vpc_cidr_address" {
  description = "CIDR address of VPC - 10.10x.0.0/16"
}

variable "region" {
  description = "The AWS region."
  type        = string
  default     = "eu-west-1"
}

variable "aws_account_id" {
  description = "The AWS account id."
  type        = number
}

variable "custom_db_ingress_cidr_blocks" {
  type    = list(string)
  default = []
}

variable "bastion_ami" {
  description = "Bastion server ami id"
  type        = string
  default     = "ami-b02939d6"
}

variable "bastion_role_policies" {
  description = "Default bastion server role policies"
  type        = list(string)

  default = [
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/AmazonEC2FullAccess",
  ]
}

variable "install_bastion" {
  description = "Option to skip bastion installation"
  type        = bool
  default     = true
}

variable "use_default_db_ingress_cidr_blocks" {
  type    = bool
  default = true
}

variable "ips_to_route_via_nat" {
  type = list(string)

  default = []
}

// default allowed IPs (VPN/other AWS accounts/etc)
variable "default_db_ingress_cidr_blocks" {
  type = list(string)
}
