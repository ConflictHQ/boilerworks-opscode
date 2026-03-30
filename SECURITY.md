# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in Boilerworks, please report it responsibly.

**Do not open a public issue.**

Instead, email **security@weareconflict.com** with:

- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

We will acknowledge your report within 48 hours and aim to release a fix within 7 days for critical issues.

## Supported Versions

| Version | Supported |
| ------- | --------- |
| latest  | Yes       |

## Security Best Practices

When deploying Boilerworks infrastructure:

- Deploy the CloudFormation IAM user template with least-privilege permissions
- Use separate AWS accounts per environment (AWS Organizations)
- Rotate IAM access keys regularly
- Never commit secrets or access keys to the repository
- Use Secrets Manager for all application secrets
- Enable MFA on all IAM users
- Review security group rules before applying
- Use TLS 1.3 on all load balancers
- Enable encryption at rest on RDS, Redis, S3, and EFS
- Review the security model in `bootstrap.md`
