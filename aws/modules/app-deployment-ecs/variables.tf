variable "project_name" {
  description = "Project name (lowercase, alphanumeric, hyphens)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "project_name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Environment identifier (dev, stg, prd)"
  type        = string

  validation {
    condition     = contains(["dev", "stg", "prd"], var.environment)
    error_message = "Environment must be one of: dev, stg, prd."
  }
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "domain" {
  description = "Domain name for the application"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "container_image" {
  description = "Docker image for the ECS task"
  type        = string
  default     = "nginx:latest"
}

variable "ecs_task_cpu" {
  description = "ECS task CPU units"
  type        = number
  default     = 512
}

variable "ecs_task_memory" {
  description = "ECS task memory (MiB)"
  type        = number
  default     = 1024
}

variable "db_instance_class" {
  description = "RDS instance class (dev only, prod uses Aurora Serverless)"
  type        = string
  default     = "db.t4g.micro"
}

variable "aurora_min_capacity" {
  description = "Aurora Serverless v2 minimum ACU (prod only)"
  type        = number
  default     = 0.5
}

variable "aurora_max_capacity" {
  description = "Aurora Serverless v2 maximum ACU (prod only)"
  type        = number
  default     = 16
}

variable "redis_node_type" {
  description = "ElastiCache Redis node type"
  type        = string
  default     = "cache.t4g.micro"
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
