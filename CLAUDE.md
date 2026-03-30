# Boilerworks Opscode — Agent Guide

Multi-cloud infrastructure-as-code templates for deploying Boilerworks applications.

## Quick Orientation

```
aws/                    AWS infrastructure (fully implemented)
  tf-backend/           Layer 0: S3 + DynamoDB state backend
  environments/dev/     Development environment (all resources)
  environments/stg/     Staging environment (prod topology, reduced scale)
  environments/prd/     Production environment (HA, Aurora, multi-AZ)
  modules/              Reusable modules
  scripts/              Bootstrap and verification scripts
gcp/                    GCP infrastructure (structured placeholders)
azure/                  Azure infrastructure (structured placeholders)
run.sh                  Command center for all operations
```

## Conventions

**Read bootstrap.md first** — it covers the full infrastructure topology.

### Naming

All resources follow `{env}-{project}-{component}`:
- `dev-boilerworks-alb`, `prd-boilerworks-db`, `dev-boilerworks-redis`

### Tags

Every resource must have these tags:
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

### File Naming

- Dev files: `dev-*.tf` (e.g., `dev-ecs.tf`, `dev-rds.tf`)
- Stg files: `stg-*.tf` (e.g., `stg-ecs.tf`, `stg-rds.tf`)
- Prod files: `prd-*.tf` (e.g., `prd-ecs.tf`, `prd-rds.tf`)
- Each module: `main.tf`, `variables.tf`, `outputs.tf`, `README.md`

### Provider Versions

- Terraform: `>= 1.5`
- AWS: `~> 5.0`
- GCP: `~> 5.0`
- Azure: `~> 3.0`

## Common Operations

```bash
./run.sh init aws dev       # initialize environment
./run.sh plan aws dev       # preview changes
./run.sh apply aws dev      # apply changes
./run.sh fmt                # format all .tf files
./run.sh validate           # validate all directories
./run.sh bootstrap aws      # first-time state backend setup
```

## Rules

- No hardcoded AWS account IDs — use `data.aws_caller_identity`
- No secrets in code — use variables or Secrets Manager
- Tags on every resource
- `terraform fmt -check` must pass
- `terraform validate` must pass in every module
- Use `lifecycle { ignore_changes }` for values managed externally (secrets, task definitions)
