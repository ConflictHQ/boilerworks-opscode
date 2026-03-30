# tf-backend-bootstrap

Creates the S3 bucket and DynamoDB table required for Terraform remote state management.

Run this module **once per AWS account** before applying any other infrastructure.

## Usage

```hcl
module "tf_backend" {
  source = "../../modules/tf-backend-bootstrap"

  project_name = "boilerworks"
  region       = "us-west-2"

  tags = {
    Service   = "boilerworks"
    Owner     = "conflict"
    ManagedBy = "terraform"
  }
}
```

## Resources Created

- **S3 Bucket** — Versioned, encrypted (AES256), public access blocked
- **DynamoDB Table** — PAY_PER_REQUEST, used for state locking

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| project_name | Project name for bucket/table naming | string | — | yes |
| region | AWS region | string | us-west-2 | no |
| tags | Tags to apply to all resources | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| bucket_name | S3 bucket name |
| bucket_arn | S3 bucket ARN |
| dynamodb_table_name | DynamoDB table name |
| dynamodb_table_arn | DynamoDB table ARN |
