# app-deployment-ecs

Flagship module that provisions a complete Boilerworks application environment on AWS using ECS Fargate.

A single invocation creates: VPC, subnets, NAT, ALB, ECS cluster + service, RDS (standard for dev, Aurora Serverless v2 for prod), ElastiCache Redis, S3, Route53, ACM, Secrets Manager, CloudWatch, security groups, and IAM roles.

## Usage

```hcl
module "app" {
  source = "../../modules/app-deployment-ecs"

  project_name    = "boilerworks"
  environment     = "dev"
  domain          = "dev.boilerworks.net"
  vpc_cidr        = "10.0.0.0/16"
  container_image = "123456789.dkr.ecr.us-west-2.amazonaws.com/boilerworks:latest"

  tags = {
    Owner = "conflict"
  }
}
```

## Environment Differences

| Feature | dev | prd |
|---------|-----|-----|
| NAT Gateway | Single | Per-AZ |
| RDS | Standard Postgres | Aurora Serverless v2 |
| Redis nodes | 1 | 3 (multi-AZ) |
| ECS desired count | 1 | 2 |
| Log retention | 7 days | 30 days |
| ALB deletion protection | No | Yes |
| RDS deletion protection | No | Yes |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| project_name | Project identifier | string | — | yes |
| environment | Environment (dev/stg/prd) | string | — | yes |
| domain | Application domain | string | — | yes |
| region | AWS region | string | us-west-2 | no |
| vpc_cidr | VPC CIDR block | string | 10.0.0.0/16 | no |
| container_image | ECS task Docker image | string | nginx:latest | no |
| ecs_task_cpu | ECS task CPU units | number | 512 | no |
| ecs_task_memory | ECS task memory (MiB) | number | 1024 | no |
| db_instance_class | RDS instance class (dev) | string | db.t4g.micro | no |
| aurora_min_capacity | Aurora min ACU (prod) | number | 0.5 | no |
| aurora_max_capacity | Aurora max ACU (prod) | number | 16 | no |
| redis_node_type | Redis node type | string | cache.t4g.micro | no |
| tags | Additional tags | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | VPC ID |
| alb_dns_name | ALB DNS name |
| ecs_cluster_name | ECS cluster name |
| rds_endpoint | Database endpoint |
| redis_endpoint | Redis endpoint |
| s3_bucket_name | File storage bucket |
| route53_nameservers | DNS nameservers |
| domain | Application domain |
