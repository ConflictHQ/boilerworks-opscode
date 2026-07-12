# Calliope — Boilerworks Opscode
<!-- Agent shim for https://github.com/calliopeai/calliope-cli -->

Primary conventions doc: [`bootstrap.md`](bootstrap.md)

Read it before writing any code.

---

## Project-specific notes

- Multi-cloud Terraform IaC for deploying Boilerworks apps; AWS is production-ready, GCP and Azure are experimental.
- Naming `{env}-{project}-{component}`; required tags (Name, Service, Owner, Environment, Region, ManagedBy) on every resource.
- `container_runtime.tf` loads `ecs/`/`eks/` submodules via boolean flags; each runtime is self-contained, shared infra stays at the environment root. Declarative over DRY — copy module blocks, don't abstract.
- No hardcoded account IDs (use `data.aws_caller_identity`) or secrets (use Secrets Manager); `lifecycle { ignore_changes }` on secrets and task definitions.
- `terraform fmt` + `terraform validate` before every commit; never `apply` without `plan` first, never modify or destroy production without explicit instruction.
- `./run.sh` drives init/plan/apply/destroy/bootstrap; push over SSH with `git push origin main`.
