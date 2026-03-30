# -----------------------------------------------------------------------------
# Container Runtime Loader
#
# Enables ECS, EKS, or both. Set via variables:
#   enable_ecs = true   (default)
#   enable_eks = false   (default)
#
# Each runtime brings its own ALB, security groups, IAM roles, log groups,
# and DNS records. Shared infrastructure (VPC, RDS, Redis, S3, Secrets,
# ACM, Route53 zone) lives in the environment root.
# -----------------------------------------------------------------------------

module "ecs" {
  count  = var.enable_ecs ? 1 : 0
  source = "./ecs"

  name               = local.name
  env                = local.env
  region             = local.region
  tags               = local.tags
  vpc_id             = module.vpc.vpc_id
  vpc_cidr           = local.vpc_cidr
  public_subnets     = module.vpc.public_subnets
  private_subnets    = module.vpc.private_subnets
  certificate_arn    = aws_acm_certificate.wildcard.arn
  route53_zone_id    = aws_route53_zone.main.zone_id
  domain             = local.domain
  sns_topic_arn      = aws_sns_topic.alerts.arn
  db_credentials_arn = aws_secretsmanager_secret.db_credentials.arn
  app_secrets_arn    = aws_secretsmanager_secret.app_secrets.arn
  s3_bucket_arn      = aws_s3_bucket.files.arn
  container_image    = var.container_image
  ecs_task_cpu       = var.ecs_task_cpu
  ecs_task_memory    = var.ecs_task_memory
  account_id         = data.aws_caller_identity.current.account_id
}

module "eks" {
  count  = var.enable_eks ? 1 : 0
  source = "./eks"

  name            = local.name
  env             = local.env
  region          = local.region
  tags            = local.tags
  vpc_id          = module.vpc.vpc_id
  vpc_cidr        = local.vpc_cidr
  private_subnets = module.vpc.private_subnets
  account_id      = data.aws_caller_identity.current.account_id
}
