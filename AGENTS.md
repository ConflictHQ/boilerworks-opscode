# Boilerworks Opscode — Agent Configuration

## Agent Roles

### Infrastructure Agent

**Purpose:** Create, modify, and manage Terraform infrastructure definitions.

**Capabilities:**
- Read and modify `.tf` files across all cloud providers
- Run `terraform fmt`, `terraform validate`, `terraform plan`
- Create new modules following existing patterns
- Add resources to existing environments

**Constraints:**
- Never run `terraform apply` or `terraform destroy` without explicit human approval
- Never hardcode AWS account IDs, secrets, or credentials
- Always add tags to every resource
- Always run `terraform fmt` after modifying `.tf` files
- Always run `terraform validate` after structural changes

**Entry Points:**
- `CLAUDE.md` — conventions and quick reference
- `bootstrap.md` — full infrastructure topology
- `BUILD_SPEC.md` — original build specification

### Operations Agent

**Purpose:** Execute infrastructure operations and verify deployments.

**Capabilities:**
- Run `./run.sh` commands for init, plan, apply
- Execute bootstrap and cold-boot scripts
- Check AWS resource status via CLI
- Verify health endpoints

**Constraints:**
- Never apply to production without explicit approval
- Always plan before apply
- Always run cold-boot verification after apply

## Context Loading

When working on this repo, agents should read in this order:

1. `CLAUDE.md` — conventions and rules
2. `bootstrap.md` — infrastructure topology
3. The specific files being modified
4. Reference implementations if patterns are unclear:
   - `/tmp/calliope-opscode/` — Calliope patterns
   - `/tmp/veracall-omni/infrastructure/` — Veracall patterns
