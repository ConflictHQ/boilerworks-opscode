# Contributing to Boilerworks Opscode

Thank you for your interest in contributing!

## Getting Started

1. Fork the repository
2. Clone your fork
3. Read `bootstrap.md` for infrastructure topology and conventions
4. Create a feature branch from `main`

## Development Process

1. Pick an issue from the project board
2. Comment your plan on the issue before starting
3. Create a branch: `feature/issue-number-description` or `fix/issue-number-description`
4. Make your changes following `bootstrap.md` conventions
5. Run `terraform fmt -recursive` before committing
6. Run `terraform validate` in any modified directories
7. Submit a pull request

## Code Style

- All resources follow `{env}-{project}-{component}` naming
- Tags on every resource (Name, Service, Owner, Environment, Region, ManagedBy)
- No hardcoded AWS account IDs or secrets
- `>= 5.0` for AWS provider, `>= 1.5` for Terraform
- Every module has: `main.tf`, `variables.tf`, `outputs.tf`, `README.md`

## Testing

- `terraform fmt -check -recursive` must pass
- `terraform validate` must pass in all directories
- `terraform plan` should produce a clean plan (no errors)

## Questions?

Open an issue or start a discussion in this repository.
