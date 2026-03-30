# bastion

SSH jump host for accessing private resources (RDS, Redis, ECS exec) in a VPC.

## Usage

```hcl
module "bastion" {
  source = "../../modules/bastion"

  name        = "dev-boilerworks"
  vpc_id      = module.vpc.vpc_id
  subnet_id   = module.vpc.public_subnets[0]
  allowed_ips = ["203.0.113.0/32"]
  key_name    = "my-keypair"
}
```

## Resources Created

- EC2 instance (Amazon Linux 2023, t3.micro)
- Security group (SSH from allowed IPs only)

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| name | Name prefix | string | — | yes |
| vpc_id | VPC ID | string | — | yes |
| subnet_id | Public subnet ID | string | — | yes |
| allowed_ips | CIDR blocks for SSH | list(string) | — | yes |
| key_name | EC2 key pair name | string | — | yes |
| instance_type | EC2 instance type | string | t3.micro | no |
| tags | Tags for all resources | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| instance_id | EC2 instance ID |
| public_ip | Bastion public IP |
| security_group_id | Bastion security group ID |
