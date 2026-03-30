# boilerworks-opscode

Multi-cloud infrastructure-as-code templates for deploying [Boilerworks](https://github.com/conflict/boilerworks) applications. Currently AWS-only with GCP and Azure structured for future expansion.

## What's Inside

| Cloud | Status | Compute | Database | Cache |
|-------|--------|---------|----------|-------|
| AWS | Full implementation | ECS Fargate | RDS / Aurora Serverless v2 | ElastiCache Redis 7 |
| GCP | Structured placeholder | Cloud Run | Cloud SQL | Memorystore |
| Azure | Structured placeholder | Container Apps | PostgreSQL Flexible | Azure Cache for Redis |

## Quick Start

```bash
# Prerequisites: Terraform >= 1.5, AWS CLI configured

# 1. Bootstrap the state backend
./run.sh bootstrap aws

# 2. Initialize and plan the dev environment
./run.sh init aws dev
./run.sh plan aws dev

# 3. Apply when ready
./run.sh apply aws dev

# 4. Verify deployment
./aws/scripts/cold-boot.sh dev
```

## Commands

```bash
./run.sh init aws dev       # terraform init
./run.sh plan aws dev       # terraform plan
./run.sh apply aws dev      # terraform apply
./run.sh destroy aws dev    # terraform destroy
./run.sh fmt                # format all .tf files
./run.sh validate           # validate all directories
./run.sh bootstrap aws      # first-time setup
```

## Architecture

```
aws/
  tf-backend/             # Layer 0: S3 + DynamoDB state backend
  environments/
    dev/                  # Development (single NAT, standard RDS, 1 Redis node)
    stg/                  # Staging (multi-AZ NAT, standard RDS multi-AZ, 2 Redis nodes)
    prd/                  # Production (multi-AZ NAT, Aurora Serverless v2, 3 Redis nodes)
  modules/
    tf-backend-bootstrap/ # Create state backend in a new account
    app-deployment-ecs/   # Full ECS Fargate deployment (flagship)
    bastion/              # SSH jump host
    dns-exposure/         # Route53 + optional Cloudflare
  scripts/
    bootstrap.sh          # First-time infrastructure setup
    cold-boot.sh          # Post-deployment verification
```

See [bootstrap.md](bootstrap.md) for the full infrastructure topology.

## Documentation

- [bootstrap.md](bootstrap.md) — Infrastructure topology and first-time setup
- [CLAUDE.md](CLAUDE.md) — Agent conventions and quick reference
- [AGENTS.md](AGENTS.md) — Agent roles and configuration
- [BUILD_SPEC.md](BUILD_SPEC.md) — Original build specification

---

Boilerworks is a [Conflict](https://weareconflict.com) brand. CONFLICT is a registered trademark of Conflict LLC.
