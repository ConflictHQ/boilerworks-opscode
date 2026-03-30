variable "domain" {
  description = "Domain name to create records for"
  type        = string
}

variable "alb_dns_name" {
  description = "ALB DNS name to alias to"
  type        = string
}

variable "alb_zone_id" {
  description = "ALB hosted zone ID"
  type        = string
}

variable "zone_id" {
  description = "Route53 hosted zone ID"
  type        = string
}

variable "create_wildcard" {
  description = "Whether to create a wildcard A record"
  type        = bool
  default     = true
}

variable "cloudflare_nameservers" {
  description = "Cloudflare nameservers for delegation (empty = no delegation)"
  type        = list(string)
  default     = []
}
