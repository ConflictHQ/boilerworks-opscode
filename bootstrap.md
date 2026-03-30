# Boilerworks Opscode — Infrastructure Bootstrap

Multi-cloud infrastructure-as-code templates for deploying Boilerworks applications. AWS fully implemented with ECS Fargate and EKS Kubernetes runtimes. GCP and Azure structured for future expansion.

## Configuration

All settings live in `aws/config.env`:

```bash
PROJECT="boilerworks"       # Used in all resource naming
AWS_REGION="us-west-2"      # Default region for all environments
OWNER="conflict"            # Owner tag value
```

Edit this file before bootstrapping. Every script and command reads from it.

## AWS Account Setup

### Step 0: Create the Infrastructure IAM User

Before Terraform can run, you need an IAM user with provisioning permissions. Deploy the CloudFormation template:

```bash
aws cloudformation deploy \
  --template-file aws/cloudformation/infra-user.yml \
  --stack-name boilerworks-infra-user \
  --parameter-overrides ProjectSlug=boilerworks \
  --capabilities CAPABILITY_NAMED_IAM
```

Then configure your local AWS profile with the output credentials:

```bash
aws configure --profile boilerworks-infra
# Enter AccessKeyId and SecretAccessKey from CloudFormation outputs
```

For multi-account setups (AWS Organizations), repeat per account:

```bash
# Dev account
AWS_PROFILE=admin aws cloudformation deploy ... --stack-name boilerworks-dev-infra-user
aws configure --profile boilerworks-dev-infra

# Prd account
AWS_PROFILE=prd-admin aws cloudformation deploy ... --stack-name boilerworks-prd-infra-user
aws configure --profile boilerworks-prd-infra
```

### Step 1: Bootstrap State Backends

Each environment gets its own S3 bucket + DynamoDB table:

```bash
# Single account — bootstrap all environments at once
./run.sh bootstrap aws all

# Multi-account — bootstrap each with the right profile
AWS_PROFILE=boilerworks-dev-infra ./run.sh bootstrap aws dev
AWS_PROFILE=boilerworks-stg-infra ./run.sh bootstrap aws stg
AWS_PROFILE=boilerworks-prd-infra ./run.sh bootstrap aws prd
```

This creates:
- `tf-state.boilerworks-dev.net` / `boilerworks-dev-tfstate-lock`
- `tf-state.boilerworks-stg.net` / `boilerworks-stg-tfstate-lock`
- `tf-state.boilerworks-prd.net` / `boilerworks-prd-tfstate-lock`

### Step 2: Plan and Apply

```bash
./run.sh plan aws dev       # Review what will be created
./run.sh apply aws dev      # Create the infrastructure
./aws/scripts/cold-boot.sh dev   # Verify deployment health
```

## Environment Topology

```
AWS Account(s)
├── dev environment
│   ├── VPC: 10.0.0.0/16, 3 AZs, single NAT
│   ├── container_runtime.tf → ecs/ (enabled) or eks/ (disabled)
│   │   └── ECS Fargate: 512 CPU, 1 GiB, min 1 / max 4
│   │       ├── ALB (HTTPS + redirect)
│   │       ├── Target group → :8000/health/
│   │       └── Auto-scaling (CPU 70%, memory 70%)
│   ├── RDS: PostgreSQL 16, db.t4g.micro, 7-day backups
│   ├── ElastiCache: Redis 7.1, single node
│   ├── S3: {name}-files (versioned, encrypted, CORS)
│   ├── Secrets Manager: db-credentials, app-secrets
│   ├── ACM: wildcard cert (*.dev.boilerworks.net)
│   ├── Route53: dev.boilerworks.net
│   ├── CloudWatch: 7-day log retention, CPU/memory/5xx alarms
│   └── SNS: alerts topic
│
├── stg environment
│   ├── VPC: 10.50.0.0/16, 3 AZs, NAT per AZ
│   ├── ECS Fargate: 1024 CPU, 2 GiB, min 2 / max 6
│   ├── RDS: PostgreSQL 16, db.t4g.small, multi-AZ, 14-day backups
│   ├── ElastiCache: Redis 7.1, 2 nodes multi-AZ
│   └── CloudWatch: 14-day log retention
│
└── prd environment
    ├── VPC: 10.100.0.0/16, 3 AZs, NAT per AZ
    ├── ECS Fargate: 1024 CPU, 2 GiB, min 2 / max 10
    ├── RDS: Aurora Serverless v2, 0.5–16 ACU, 30-day backups
    ├── ElastiCache: Redis 7.1, 3 nodes multi-AZ
    └── CloudWatch: 30-day log retention
```

## Container Runtime

Each environment has `container_runtime.tf` that loads `ecs/` and/or `eks/` as submodules:

```hcl
# variables.tf
enable_ecs = true    # ECS Fargate (default)
enable_eks = false   # EKS Kubernetes (opt-in)
```

Both can coexist. Each runtime brings its own ALB, security groups, IAM roles, log groups, and DNS records. Shared infrastructure (VPC, RDS, Redis, S3, Secrets, ACM) is in the environment root.

To add a second ECS service: copy the `module "ecs"` block in `container_runtime.tf`, change the name and inputs.

### ECS Runtime

- ECS Fargate cluster + service + task definition
- ALB with HTTPS (TLS 1.3) + HTTP→HTTPS redirect
- Target group health check on `/health/`
- Auto-scaling on CPU + memory
- IAM: execution role (pull images, read secrets) + task role (S3, SES, logs)
- CI/CD IAM role for deployments
- CloudWatch log group + CPU/memory/5xx alarms
- Route53 A records (root + wildcard) → ALB

### EKS Runtime

- EKS cluster (Kubernetes 1.33) with managed spot node groups
- CoreDNS, kube-proxy, vpc-cni addons with IRSA
- ALB controller IRSA for Ingress management
- EFS with KMS encryption for persistent storage
- aws-auth ConfigMap bootstrap
- CloudWatch log group

## Terraform Structure

```
aws/
  config.env                    # PROJECT, AWS_REGION, OWNER
  cloudformation/
    infra-user.yml              # IAM user for Terraform (run first)
  tf-backend/                   # Layer 0: state backend resources
  environments/
    {dev,stg,prd}/
      main.tf                   # Backend config (empty — injected at init)
      versions.tf               # Provider constraints
      variables.tf              # enable_ecs, enable_eks, region, etc.
      container_runtime.tf      # Loader for ecs/ and eks/ submodules
      {env}-vpc.tf              # VPC, subnets, NAT, VPC endpoints
      {env}-rds.tf              # PostgreSQL / Aurora
      {env}-elasticache.tf      # Redis
      {env}-s3.tf               # File storage
      {env}-secrets.tf          # Secrets Manager
      {env}-acm.tf              # TLS certificates
      {env}-route53.tf          # DNS zone
      {env}-sg.tf               # Shared security groups (RDS, Redis, bastion)
      {env}-cloudwatch.tf       # SNS alerts topic
      {env}-bastion.tf          # Optional SSH jump host
      ecs/                      # ECS Fargate submodule
        main.tf, variables.tf, outputs.tf
      eks/                      # EKS Kubernetes submodule
        main.tf, variables.tf, outputs.tf
  modules/
    tf-backend-bootstrap/       # S3 + DynamoDB for a new account
    app-deployment-ecs/         # All-in-one ECS deployment module
    bastion/                    # SSH jump host
    dns-exposure/               # Route53 + Cloudflare delegation
  scripts/
    bootstrap.sh                # Create backend + init environments
    cold-boot.sh                # Post-deploy health verification
```

## Naming Convention

All resources: `{env}-{project}-{component}`

| Resource | Example |
|----------|---------|
| ECS cluster | `dev-boilerworks` |
| ALB | `dev-boilerworks-alb` |
| RDS | `dev-boilerworks-db` |
| Redis | `dev-boilerworks-redis` |
| S3 bucket | `dev-boilerworks-files` |
| Log group | `/aws/ecs/dev-boilerworks` |
| IAM role | `dev-boilerworks-ecs-exec` |

## Tags (mandatory on every resource)

```hcl
tags = {
  Name        = "dev-boilerworks"
  Service     = "boilerworks"
  Owner       = "conflict"
  Environment = "development"
  Region      = "us-west-2"
  ManagedBy   = "terraform"
}
```

## Security Model

```
Internet → ALB (public subnets, 80/443)
             → ECS/EKS (private subnets)
                → RDS (database subnets, 5432 from VPC)
                → Redis (cache subnets, 6379 from VPC)
```

- No hardcoded AWS account IDs — use `data.aws_caller_identity`
- No secrets in code — use Secrets Manager
- `lifecycle { ignore_changes }` on secrets and task definitions
- TLS 1.3 on all ALBs
- Storage encryption on RDS, Redis, S3, EFS

## Common Commands

```bash
# Terraform
./run.sh init aws dev           # Initialize (configures backend)
./run.sh plan aws dev           # Preview changes
./run.sh apply aws dev          # Apply changes
./run.sh fmt                    # Format all .tf files
./run.sh validate               # Validate all directories

# Bootstrap
./run.sh bootstrap aws dev      # Create backend + init for dev
./run.sh bootstrap aws all      # All environments

# Verify
./aws/scripts/cold-boot.sh dev  # Health check after deploy

# Switch runtime
terraform -chdir=aws/environments/dev apply -var="enable_eks=true"
```
