# Boilerworks Opscode — Agent Configuration

## Agent Shims

Each AI coding agent has its own entry point that follows the same pattern: read `bootstrap.md` first, then follow the conventions.

| Agent | Shim File | Notes |
|-------|-----------|-------|
| Claude | `CLAUDE.md` | Read by Claude Code, Cursor, Windsurf |
| Codex | `CODEX.md` | Read by OpenAI Codex, ChatGPT, Copilot Workspace |

All shims point to `bootstrap.md` as the single source of truth for infrastructure context.

## Conventions (all agents)

- Read `bootstrap.md` before any work
- No co-authorship messages in commits
- No rebases
- `terraform fmt` before every commit
- `terraform validate` must pass
- Tags on every resource
- No hardcoded account IDs or secrets
- Declarative over DRY — copy module blocks, don't abstract

## Agent Roles

### Infrastructure Agent

**Purpose:** Create, modify, and manage Terraform infrastructure.

**Can do:**
- Read and modify `.tf` files
- Run `terraform fmt`, `terraform validate`, `terraform plan`
- Create new modules following existing patterns
- Copy module blocks in `container_runtime.tf` to add services

**Must not:**
- Run `terraform apply` or `terraform destroy` without explicit approval
- Modify production without explicit instruction
- Hardcode AWS account IDs, secrets, or credentials

### Operations Agent

**Purpose:** Execute infrastructure operations and verify deployments.

**Can do:**
- Run `./run.sh` commands (init, plan, apply)
- Execute bootstrap and cold-boot scripts
- Check AWS resource status via CLI
- Verify health endpoints

**Must not:**
- Apply to production without explicit approval
- Skip `terraform plan` before `terraform apply`

## Context Loading Order

1. `CLAUDE.md` / `CODEX.md` — agent-specific conventions
2. `bootstrap.md` — full infrastructure topology and setup guide
3. `aws/config.env` — project configuration
4. The specific files being modified
