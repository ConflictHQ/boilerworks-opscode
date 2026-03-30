# Build Spec — Boilerworks Opscode (Infrastructure Templates)

## Context

Build a multi-cloud infrastructure-as-code template for deploying Boilerworks applications. Currently AWS-only with GCP and Azure structured for future expansion.

## Required Reading

1. `/tmp/calliope-opscode/` — reference implementation (AWS, Terraform, Ansible)
2. `/tmp/veracall-omni/infrastructure/` — second reference (AWS, Terraform)
3. `../primers/PROCESS.md` — development standards
4. `../primers/CATALOGUE.md` — what Boilerworks is

Study both reference repos to understand the patterns. The Boilerworks opscode should follow the SAME conventions (layered bootstrap, environment separation, reusable modules, tagged resources).

## Architecture

```
boilerworks-opscode/
├── README.md
├── CLAUDE.md
├── bootstrap.md
├── AGENTS.md
├── run.sh                          # Command center
├── Makefile
│
├── aws/                            # AWS infrastructure
│   ├── tf-backend/                 # Layer 0: S3 + DynamoDB state backend
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── environments/
│   │   ├── dev/                    # Development environment
│   │   │   ├── main.tf            # Backend config + locals + tags
│   │   │   ├── versions.tf        # Provider + terraform version constraints
│   │   │   ├── variables.tf       # Environment-specific defaults
│   │   │   ├── dev-vpc.tf         # VPC + subnets + NAT
│   │   │   ├── dev-ecs.tf         # ECS Fargate cluster + services
│   │   │   ├── dev-rds.tf         # Aurora Serverless v2 or RDS Postgres
│   │   │   ├── dev-elasticache.tf # Redis cluster
│   │   │   ├── dev-alb.tf         # Application Load Balancer
│   │   │   ├── dev-route53.tf     # DNS zones + records
│   │   │   ├── dev-acm.tf         # TLS certificates
│   │   │   ├── dev-s3.tf          # File storage bucket
│   │   │   ├── dev-secrets.tf     # Secrets Manager
│   │   │   ├── dev-cloudwatch.tf  # Log groups + alarms
│   │   │   ├── dev-sg.tf          # Security groups
│   │   │   ├── dev-iam.tf         # IAM roles + policies (ECS task, CI/CD)
│   │   │   └── dev-bastion.tf     # Optional bastion host
│   │   │
│   │   └─�� prd/                    # Production environment (same files, different values)
│   │       ├── main.tf
│   │       ├── versions.tf
│   │       ├── variables.tf
│   │       ├── prd-vpc.tf
│   │       ├── prd-ecs.tf
│   │       ├── prd-rds.tf
│   │       ├── prd-elasticache.tf
│   │       ├── prd-alb.tf
│   │       ├── prd-route53.tf
│   │       ├── prd-acm.tf
│   │       ├── prd-s3.tf
│   │       ├── prd-secrets.tf
│   │       ├── prd-cloudwatch.tf
│   │       ├── prd-sg.tf
│   │       ├── prd-iam.tf
│   │       └── prd-bastion.tf
│   │
│   ├── modules/                    # Reusable modules
│   │   ├── tf-backend-bootstrap/   # Create S3 + DynamoDB in a new account
│   │   ├── app-deployment-ecs/     # Full ECS Fargate deployment (VPC, ALB, ECS, RDS, Redis, S3, DNS)
│   │   ├── bastion/                # SSH jump host
│   │   └── dns-exposure/           # Route53 + optional Cloudflare delegation
│   │
│   └── scripts/
│       ├── bootstrap.sh            # First-time infrastructure setup
│       └─��� cold-boot.sh            # Verify deployment after bootstrap
│
├── gcp/                            # GCP infrastructure (structured, minimal)
│   ├── tf-backend/                 # GCS + Cloud Storage state backend
│   │   └── main.tf
│   ├── environments/
│   │   ├── dev/
│   │   │   └── main.tf            # Placeholder with structure
│   │   └── prd/
│   │       └── main.tf
│   └── modules/
│       └── README.md               # "Coming soon" with planned services
│
├── azure/                          # Azure infrastructure (structured, minimal)
│   ├── tf-backend/                 # Azure Storage Account state backend
│   │   └── main.tf
│   ├── environments/
│   │   ├── dev/
│   │   │   └── main.tf
│   │   └── prd/
│   │       └── main.tf
│   └── modules/
│       └── README.md               # "Coming soon" with planned services
│
├── .github/
│   ├── workflows/
│   │   └── ci.yml                  # terraform fmt, validate, plan
│   ├── ISSUE_TEMPLATE/
│   ├── pull_request_template.md
│   └── dependabot.yml
│
├── LICENSE
├── CODE_OF_CONDUCT.md
├── SECURITY.md
└── CONTRIBUTING.md
```

## AWS Build Details (full implementation)

### Layer 0: tf-backend
- S3 bucket with versioning + encryption (AES256)
- DynamoDB table for state locking
- Outputs: bucket name, table name, region

### Dev Environment
Follow the calliope-opscode patterns exactly:

**VPC:**
- CIDR: 10.0.0.0/16
- 3 AZs minimum
- Public subnets (ALB, NAT)
- Private subnets (ECS tasks)
- Database subnets (RDS)
- Cache subnets (ElastiCache)
- NAT Gateway (single for dev, multi-AZ for prod)
- VPC endpoints for ECR, ECS, CloudWatch, S3

**ECS Fargate:**
- Cluster with capacity providers
- Service with task definition (image from ECR)
- Auto-scaling (min 1, max 4 for dev)
- Health check on ALB target group
- Log group with 7-day retention (dev), 30-day (prod)

**RDS:**
- Postgres 16 (Aurora Serverless v2 for prod, standard RDS for dev)
- Private subnet group
- Encrypted storage
- Automated backups (7 days dev, 30 days prod)
- Parameter group with sane defaults

**ElastiCache:**
- Redis 7 cluster mode disabled
- Single node (dev), multi-AZ replicas (prod)
- Encryption in transit + at rest

**ALB:**
- HTTPS listener (443) with ACM cert
- HTTP → HTTPS redirect
- Target group with health check path (/health/)
- Security group: 80/443 from anywhere

**Route53:**
- Hosted zone for the domain
- A record aliased to ALB
- Optional: wildcard cert

**ACM:**
- Wildcard cert for *.domain.com
- DNS validation via Route53

**S3:**
- File storage bucket (private, versioned)
- CORS configured for the app domain
- Lifecycle rules (optional)

**Secrets Manager:**
- Database credentials
- App secrets (SESSION_SECRET, API keys)
- `lifecycle { ignore_changes = [secret_string] }` — set once, manage externally

**CloudWatch:**
- Log groups per ECS service
- Basic alarms: CPU > 80%, memory > 80%, 5xx > 10/min
- SNS topic for alerts

**Security Groups:**
- ALB: 80/443 inbound from 0.0.0.0/0
- ECS: all from ALB SG only
- RDS: 5432 from ECS SG only
- Redis: 6379 from ECS SG only
- Bastion: 22 from specific IPs

**IAM:**
- ECS task execution role (pull ECR, read secrets, write logs)
- ECS task role (S3 access, SES access)
- CI/CD role (deploy to ECS, push to ECR)

### Prod Environment
Same resources as dev with production differences:
- Multi-AZ everything (NAT, RDS, Redis)
- Higher instance sizes
- Longer log retention (30 days)
- More aggressive auto-scaling (min 2, max 10)
- Aurora Serverless v2 instead of standard RDS
- Multi-AZ Redis replicas
- Stricter security groups

### Modules

**tf-backend-bootstrap:**
- Inputs: project_name, region
- Creates: S3 bucket, DynamoDB table
- Outputs: bucket_name, table_name

**app-deployment-ecs (flagship):**
- Inputs: project_name, environment, domain, vpc_cidr, container_image, db_instance_class, etc.
- Creates: EVERYTHING (VPC, ECS, RDS, Redis, ALB, Route53, ACM, S3, Secrets, CloudWatch, SG, IAM)
- Outputs: alb_dns, rds_endpoint, redis_endpoint, s3_bucket

**bastion:**
- Inputs: vpc_id, subnet_id, allowed_ips, key_name
- Creates: EC2 instance, security group

**dns-exposure:**
- Inputs: domain, alb_dns, zone_id
- Creates: Route53 records, optional Cloudflare delegation

### Naming Convention
All resources follow: `{env}-{project}-{component}`
- ECS cluster: `dev-boilerworks`
- S3 bucket: `dev-boilerworks-files`
- RDS: `dev-boilerworks-db`
- Log group: `/aws/ecs/dev/boilerworks`

### Tags (mandatory on every resource)
```hcl
locals {
  tags = {
    Name        = "dev-boilerworks"
    Service     = "boilerworks"
    Owner       = "conflict"
    Environment = "development"
    Region      = "us-west-2"
    ManagedBy   = "terraform"
  }
}
```

## GCP & Azure (structure only)

### GCP tf-backend
- GCS bucket for state
- Placeholder main.tf with comments showing planned services:
  - Cloud Run (compute)
  - Cloud SQL Postgres (database)
  - Memorystore Redis (cache)
  - Cloud Load Balancing
  - Cloud DNS
  - Cloud Storage (files)
  - Secret Manager

### Azure tf-backend
- Azure Storage Account for state
- Placeholder main.tf with comments showing planned services:
  - Azure Container Apps (compute)
  - Azure Database for PostgreSQL (database)
  - Azure Cache for Redis
  - Application Gateway
  - Azure DNS
  - Azure Blob Storage (files)
  - Azure Key Vault (secrets)

## Quality Rules

- `terraform fmt -check` must pass
- `terraform validate` must pass in every directory
- No hardcoded AWS account IDs — use `data.aws_caller_identity`
- No secrets in code — use variables or Secrets Manager
- Version constraints on all providers (`~> 5.0` for AWS)
- Version constraint on Terraform itself (`>= 1.5`)
- Tags on every resource
- Use terraform-aws-modules where available (VPC, ECS, ALB, RDS)
- Every module has: main.tf, variables.tf, outputs.tf, README.md
- CI: fmt + validate on every PR

## run.sh Commands

```bash
./run.sh init aws dev       # terraform init for AWS dev
./run.sh plan aws dev       # terraform plan
./run.sh apply aws dev      # terraform apply
./run.sh destroy aws dev    # terraform destroy
./run.sh fmt                # format all .tf files
./run.sh validate           # validate all directories
./run.sh bootstrap aws      # first-time tf-backend setup
```

## Completion

When ALL of the following are true:
- AWS tf-backend works (init + plan clean)
- AWS dev environment plans cleanly (all resources defined)
- AWS prd environment plans cleanly
- All 4 modules have main.tf + variables.tf + outputs.tf + README.md
- GCP and Azure have structured placeholders
- `terraform fmt -check` passes everywhere
- `terraform validate` passes in tf-backend and modules
- CI pipeline validates on PR
- README, CLAUDE.md, bootstrap.md are real (not stubs)
- run.sh works for all commands

The template is done.
