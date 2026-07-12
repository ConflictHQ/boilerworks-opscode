# boilerworks-opscode

Multi-cloud infrastructure-as-code templates for deploying [Boilerworks](https://github.com/ConflictHQ/boilerworks) applications. AWS is production ready; GCP and Azure are experimental, with dev environments in-tree.

## What's Inside

| Cloud | Status | Compute | Database | Cache |
|-------|--------|---------|----------|-------|
| AWS | Production ready | ECS Fargate / EKS | RDS / Aurora Serverless v2 | ElastiCache Redis 7 |
| GCP | Experimental | Cloud Run / GKE | Cloud SQL PostgreSQL | Memorystore Redis |
| Azure | Experimental | Container Apps / AKS | PostgreSQL Flexible Server | Azure Cache for Redis |

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
kubernetes/
  base/                   # Cluster base platform for EKS/GKE/AKS: Gateway API,
                          # Envoy Gateway, cert-manager, external-secrets,
                          # external-dns, Fluent Bit, Loki, Prometheus, Argo CD
  values/                 # Cloud-specific Helm values
```

See [bootstrap.md](bootstrap.md) for the full infrastructure topology.

## Documentation

- [bootstrap.md](bootstrap.md) — Infrastructure topology and first-time setup
- [kubernetes/README.md](kubernetes/README.md) — Kubernetes base platform (Gateway API, observability, Argo CD)
- [CLAUDE.md](CLAUDE.md) — Agent conventions and quick reference
- [CALLIOPE.md](CALLIOPE.md) — Calliope harness shim
- [AGENTS.md](AGENTS.md) — Agent roles and configuration (also the OpenAI/Codex shim)

---

Boilerworks is a [Conflict](https://weareconflict.com) brand. CONFLICT is a registered trademark of Conflict LLC.
