# GCP Modules — Experimental

Planned modules for GCP infrastructure:

## app-deployment-cloudrun

Full Cloud Run deployment equivalent to the AWS `app-deployment-ecs` module:

- **VPC** — Custom VPC with private subnets and Cloud NAT
- **Cloud Run** — Managed container deployment with auto-scaling
- **Cloud SQL** — PostgreSQL with private VPC access
- **Memorystore** — Redis with VPC peering
- **Cloud Load Balancing** — Global HTTPS load balancer with managed SSL
- **Cloud DNS** — DNS zones and records
- **Cloud Storage** — Object storage with CORS and lifecycle rules
- **Secret Manager** — Application secrets
- **Cloud Logging** — Structured logging with sinks
- **Cloud Monitoring** — Alerting policies and uptime checks
- **IAM** — Service accounts with least-privilege bindings

## bastion

Cloud IAP tunnel-based access (no public SSH):

- Compute Engine instance in private subnet
- IAP TCP forwarding (replaces SSH bastion pattern)
- OS Login for identity-based access

## dns-exposure

Cloud DNS records with optional Cloudflare delegation.
