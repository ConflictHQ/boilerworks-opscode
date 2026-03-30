# Azure Modules — Experimental

Planned modules for Azure infrastructure:

## app-deployment-container-apps

Full Azure Container Apps deployment equivalent to the AWS `app-deployment-ecs` module:

- **Virtual Network** — Custom VNet with subnets and NAT Gateway
- **Container Apps** — Managed container deployment with auto-scaling
- **PostgreSQL Flexible Server** — Database with VNet integration
- **Azure Cache for Redis** — Redis with Private Endpoint
- **Application Gateway** — HTTPS load balancer with managed SSL
- **Azure DNS** — DNS zones and records
- **Azure Blob Storage** — Object storage with CORS and lifecycle
- **Azure Key Vault** — Application secrets and certificates
- **Log Analytics** — Centralized logging workspace
- **Azure Monitor** — Alerts, action groups, and dashboards
- **RBAC** — Managed identities with least-privilege role assignments

## bastion

Azure Bastion-based access (no public SSH):

- Azure Bastion Standard SKU
- Native RDP/SSH through Azure portal
- No public IP on target VMs

## dns-exposure

Azure DNS records with optional Cloudflare delegation.
