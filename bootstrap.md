# Boilerworks Opscode — Infrastructure Topology

## Overview

Boilerworks Opscode provisions the complete infrastructure for running Boilerworks applications across cloud providers. Currently AWS-only with GCP and Azure structured for future expansion.

## Architecture

### Layered Bootstrap

Infrastructure is deployed in layers with explicit dependencies:

```
Layer 0: State Backend (tf-backend)
  └─ S3 bucket + DynamoDB for Terraform remote state
  └─ Deploy ONCE per account, BEFORE everything else

Layer 1: Network (VPC)
  └─ VPC, subnets (public/private/database/cache), NAT Gateway
  └─ VPC endpoints (S3, ECR, ECS, CloudWatch, Secrets Manager)
  └─ VPC flow logs

Layer 2: Security
  └─ Security groups (ALB, ECS, RDS, Redis, Bastion)
  └─ IAM roles (ECS execution, ECS task, CI/CD)
  └─ ACM certificates (wildcard TLS)

Layer 3: Data
  └─ RDS PostgreSQL (standard dev, Aurora Serverless v2 prod)
  └─ ElastiCache Redis (single dev, multi-AZ prod)
  └─ S3 file storage bucket
  └─ Secrets Manager (DB credentials, app secrets)

Layer 4: Compute
  └─ ECS Fargate cluster + service
  └─ Application Load Balancer (HTTPS + HTTP→HTTPS redirect)
  └─ Auto-scaling (CPU + memory targets)

Layer 5: Observability
  └─ CloudWatch log groups
  └─ CloudWatch alarms (CPU, memory, 5xx)
  └─ SNS alert topic

Layer 6: DNS
  └─ Route53 hosted zone
  └─ A records (root + wildcard) aliased to ALB
```

## Environment Topology

### Development (dev)

| Component | Configuration |
|-----------|--------------|
| VPC | 10.0.0.0/16, 3 AZs, single NAT gateway |
| ECS | Fargate, 512 CPU / 1024 MiB, min 1 / max 4 tasks |
| RDS | PostgreSQL 16, db.t4g.micro, 7-day backups |
| Redis | Redis 7.1, cache.t4g.micro, single node |
| ALB | Public HTTPS, TLS 1.3 |
| Logs | 7-day retention |
| Domain | dev.boilerworks.net |

### Staging (stg)

| Component | Configuration |
|-----------|--------------|
| VPC | 10.50.0.0/16, 3 AZs, NAT per AZ |
| ECS | Fargate, 1024 CPU / 2048 MiB, min 2 / max 6 tasks |
| RDS | PostgreSQL 16, db.t4g.small, multi-AZ, 14-day backups |
| Redis | Redis 7.1, cache.t4g.small, 2 nodes multi-AZ |
| ALB | Public HTTPS, TLS 1.3, deletion protection |
| Logs | 14-day retention |
| Domain | stg.boilerworks.net |

### Production (prd)

| Component | Configuration |
|-----------|--------------|
| VPC | 10.100.0.0/16, 3 AZs, NAT per AZ |
| ECS | Fargate, 1024 CPU / 2048 MiB, min 2 / max 10 tasks |
| RDS | Aurora Serverless v2 PostgreSQL 16, 0.5–16 ACU, 30-day backups |
| Redis | Redis 7.1, cache.r7g.large, 3 nodes multi-AZ |
| ALB | Public HTTPS, TLS 1.3, deletion protection |
| Logs | 30-day retention |
| Domain | boilerworks.net |

## First-Time Setup

### Prerequisites

- Terraform >= 1.5
- AWS CLI configured with appropriate credentials
- An AWS account with permissions to create all resources

### Bootstrap Sequence

```bash
# 1. Create the state backend (Layer 0)
./run.sh bootstrap aws

# 2. Initialize the dev environment
./run.sh init aws dev

# 3. Review the plan
./run.sh plan aws dev

# 4. Apply
./run.sh apply aws dev

# 5. Verify deployment
./aws/scripts/cold-boot.sh dev
```

### Post-Bootstrap

After `terraform apply`:

1. **Update DNS** — Point your domain registrar's nameservers to the Route53 zone NS records
2. **Set secrets** — Update Secrets Manager values via AWS Console or CLI
3. **Push container** — Build and push your app image to ECR
4. **Deploy** — Update the ECS service with the new task definition

## Module Library

### tf-backend-bootstrap
Creates S3 + DynamoDB for a new AWS account. Run once per account.

### app-deployment-ecs (flagship)
Complete ECS Fargate deployment: VPC, ALB, ECS, RDS, Redis, S3, DNS, ACM, Secrets, CloudWatch, SG, IAM. One module invocation = one complete environment.

### bastion
SSH jump host on EC2 for accessing private resources.

### dns-exposure
Route53 records with optional Cloudflare delegation.

## Security Model

### Network Isolation

```
Internet → ALB (public subnets, 80/443)
             → ECS tasks (private subnets, all from ALB only)
                → RDS (database subnets, 5432 from ECS only)
                → Redis (cache subnets, 6379 from ECS only)
```

### IAM Roles

- **ECS Execution Role** — Pull images from ECR, read secrets, write logs
- **ECS Task Role** — S3 access, SES email, read secrets, write logs
- **CI/CD Role** — Deploy to ECS, push to ECR, pass roles

### Encryption

- RDS: Storage encrypted at rest
- Redis: Encryption in transit + at rest
- S3: AES256 server-side encryption, public access blocked
- ALB: TLS 1.3 minimum
