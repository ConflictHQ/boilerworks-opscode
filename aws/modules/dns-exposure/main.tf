# -----------------------------------------------------------------------------
# Module: dns-exposure
#
# Route53 records + optional Cloudflare delegation for exposing services.
# -----------------------------------------------------------------------------

terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# -----------------------------------------------------------------------------
# Route53 Records — A record aliased to ALB
# -----------------------------------------------------------------------------

resource "aws_route53_record" "app" {
  zone_id = var.zone_id
  name    = var.domain
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "wildcard" {
  count = var.create_wildcard ? 1 : 0

  zone_id = var.zone_id
  name    = "*.${var.domain}"
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

# -----------------------------------------------------------------------------
# Cloudflare Delegation (optional)
#
# When using Cloudflare as the public DNS provider, create NS records
# in Route53 pointing to the Cloudflare nameservers. The actual Cloudflare
# zone and records are managed outside this module.
# -----------------------------------------------------------------------------

resource "aws_route53_record" "cloudflare_ns" {
  count = length(var.cloudflare_nameservers) > 0 ? 1 : 0

  zone_id = var.zone_id
  name    = var.domain
  type    = "NS"
  ttl     = 300
  records = var.cloudflare_nameservers
}
