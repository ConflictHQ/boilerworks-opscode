# -----------------------------------------------------------------------------
# Boilerworks — Development Environment
# -----------------------------------------------------------------------------

terraform {
  backend "s3" {
    encrypt        = true
    bucket         = "tf-state.boilerworks.net"
    dynamodb_table = "boilerworks-tfstate-lock"
    key            = "aws/dev/terraform.tfstate"
    region         = "us-west-2"
  }
}

locals {
  name         = "dev-boilerworks"
  env          = "development"
  region       = "us-west-2"
  service_name = "boilerworks"
  owner        = "conflict"
  ver          = "1.0"
  domain       = "dev.boilerworks.net"
  vpc_cidr     = "10.0.0.0/16"

  azs = ["${local.region}a", "${local.region}b", "${local.region}c"]

  public_subnets   = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets  = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
  database_subnets = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]
  cache_subnets    = ["10.0.31.0/24", "10.0.32.0/24", "10.0.33.0/24"]

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
