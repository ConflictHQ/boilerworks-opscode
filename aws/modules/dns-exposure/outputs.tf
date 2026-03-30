output "app_fqdn" {
  description = "Fully qualified domain name of the A record"
  value       = aws_route53_record.app.fqdn
}

output "wildcard_fqdn" {
  description = "Fully qualified domain name of the wildcard record"
  value       = var.create_wildcard ? aws_route53_record.wildcard[0].fqdn : ""
}
