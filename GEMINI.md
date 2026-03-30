# GEMINI.md

All infrastructure topology, Terraform structure, and operational context live in **[`bootstrap.md`](./bootstrap.md)**.

Read `bootstrap.md` before working on this codebase. It contains:
- AWS account setup and IAM user provisioning
- Environment topology (dev/stg/prd) and resource specifications
- Container runtime architecture (ECS/EKS with feature flags)
- Terraform file structure, naming conventions, tagging
- Security model and encryption
- Common commands

## Quick Reference

- **Config:** `aws/config.env` (PROJECT, AWS_REGION, OWNER)
- **No co-authorship messages in commits**
- **No rebases**
- All CLI commands: respect `AWS_PROFILE` per environment

## Conventions

- **Naming:** `{env}-{project}-{component}` (e.g., `dev-boilerworks-alb`)
- **Tags:** Name, Service, Owner, Environment, Region, ManagedBy on every resource
- **Files:** `{env}-*.tf` for shared infra, `ecs/` and `eks/` for compute
- **Providers:** `>= 5.0` for AWS, `>= 1.5` for Terraform
- **No hardcoded account IDs** — use `data.aws_caller_identity`
- **No secrets in code** — use Secrets Manager
- **`lifecycle { ignore_changes }`** on secrets and task definitions
- `terraform fmt` before every commit
- `terraform validate` must pass in every directory

## Container Runtime Pattern

`container_runtime.tf` loads `ecs/` and/or `eks/` submodules via boolean flags (`enable_ecs`, `enable_eks`). Each runtime is self-contained with its own ALB, security groups, IAM roles, log groups, and DNS records. Shared infrastructure (VPC, RDS, Redis, S3) stays at the environment root.

To add a service: copy a module block in `container_runtime.tf`, rename it, adjust inputs. The pattern is declarative — copy-paste-modify, not DRY abstractions.

## Do Not

- Modify production without explicit instruction
- Run `terraform apply` without `terraform plan` first
- Hardcode AWS account IDs, regions, or secrets
- Skip tags on any resource
- Use `terraform destroy` on production
