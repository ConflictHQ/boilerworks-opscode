variable "name" {
  description = "Name prefix for bastion resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the bastion will be deployed"
  type        = string
}

variable "subnet_id" {
  description = "Public subnet ID for the bastion host"
  type        = string
}

variable "allowed_ips" {
  description = "CIDR blocks allowed to SSH into the bastion"
  type        = list(string)
}

variable "key_name" {
  description = "EC2 key pair name for SSH access"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
