# -----------------------------------------------------------------------------
# Boilerworks — Staging Environment
# -----------------------------------------------------------------------------

terraform {
  backend "s3" {
    encrypt        = true
    bucket         = "tf-state.boilerworks.net"
    dynamodb_table = "boilerworks-tfstate-lock"
    key            = "aws/stg/terraform.tfstate"
    region         = "us-west-2"
  }
}

locals {
  name         = "stg-boilerworks"
  env          = "staging"
  region       = "us-west-2"
  service_name = "boilerworks"
  owner        = "conflict"
  ver          = "1.0"
  domain       = "stg.boilerworks.net"
  vpc_cidr     = "10.50.0.0/16"

  azs = ["${local.region}a", "${local.region}b", "${local.region}c"]

  public_subnets   = ["10.50.1.0/24", "10.50.2.0/24", "10.50.3.0/24"]
  private_subnets  = ["10.50.11.0/24", "10.50.12.0/24", "10.50.13.0/24"]
  database_subnets = ["10.50.21.0/24", "10.50.22.0/24", "10.50.23.0/24"]
  cache_subnets    = ["10.50.31.0/24", "10.50.32.0/24", "10.50.33.0/24"]

  tags = {
    Name        = local.name
    Service     = local.service_name
    Owner       = local.owner
    Environment = local.env
    Region      = local.region
    ManagedBy   = "terraform"
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
