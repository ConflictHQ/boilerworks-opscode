variable "name" { type = string }
variable "env" { type = string }
variable "region" { type = string }
variable "tags" { type = map(string) }
variable "vpc_id" { type = string }
variable "vpc_cidr" { type = string }
variable "private_subnets" { type = list(string) }
variable "account_id" { type = string }
