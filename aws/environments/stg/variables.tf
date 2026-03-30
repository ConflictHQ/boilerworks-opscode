variable "region" {
  description = "AWS region for this environment"
  type        = string
  default     = "us-west-2"
}

# -----------------------------------------------------------------------------
# Staging Environment Variables
# Staging mirrors production topology at reduced scale.
# -----------------------------------------------------------------------------

# Container runtime selection — enable one or both
variable "enable_ecs" {
  description = "Enable ECS Fargate container runtime"
  type        = bool
  default     = true
}

variable "enable_eks" {
  description = "Enable EKS Kubernetes container runtime"
  type        = bool
  default     = false
}

# ECS settings
variable "container_image" {
  description = "Docker image for the ECS task (ECR URI)"
  type        = string
  default     = "nginx:latest"
}

variable "ecs_task_cpu" {
  description = "ECS task CPU units"
  type        = number
  default     = 1024
}

variable "ecs_task_memory" {
  description = "ECS task memory (MiB)"
  type        = number
  default     = 2048
}

# Database
variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t4g.small"
}

# Cache
variable "redis_node_type" {
  description = "ElastiCache Redis node type"
  type        = string
  default     = "cache.t4g.small"
}

# Bastion
variable "allowed_bastion_ips" {
  description = "CIDR blocks allowed to SSH into the bastion host"
  type        = list(string)
  default     = []
}

variable "bastion_key_name" {
  description = "EC2 key pair name for the bastion host"
  type        = string
  default     = ""
}
