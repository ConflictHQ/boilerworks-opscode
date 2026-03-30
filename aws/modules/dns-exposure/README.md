# dns-exposure

Route53 DNS records with optional Cloudflare delegation for exposing services.

## Usage

```hcl
module "dns" {
  source = "../../modules/dns-exposure"

  domain       = "app.boilerworks.net"
  alb_dns_name = module.app.alb_dns_name
  alb_zone_id  = module.app.alb_zone_id
  zone_id      = module.app.route53_zone_id

  # Optional: delegate to Cloudflare
  cloudflare_nameservers = ["ns1.cloudflare.com", "ns2.cloudflare.com"]
}
```

## Resources Created

- Route53 A record (aliased to ALB)
- Route53 wildcard A record (optional)
- Route53 NS delegation to Cloudflare (optional)

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| domain | Domain name | string | — | yes |
| alb_dns_name | ALB DNS name | string | — | yes |
| alb_zone_id | ALB hosted zone ID | string | — | yes |
| zone_id | Route53 zone ID | string | — | yes |
| create_wildcard | Create wildcard record | bool | true | no |
| cloudflare_nameservers | Cloudflare NS for delegation | list(string) | [] | no |

## Outputs

| Name | Description |
|------|-------------|
| app_fqdn | A record FQDN |
| wildcard_fqdn | Wildcard record FQDN |
