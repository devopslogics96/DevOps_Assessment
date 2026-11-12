variable "environment" {
  description = "Environment name."
  type        = string
  default     = "prod"
}

variable "aws_region" {
  description = "AWS region for all resources and the state bucket."
  type        = string
}

variable "availability_zones" {
  description = "At least two Availability Zones used by the network."
  type        = list(string)
}

variable "vpc_cidr_block" {
  description = "CIDR block for the environment VPC."
  type        = string
}

variable "public_subnet_cidr_blocks" {
  description = "Public subnet CIDR blocks, one per Availability Zone."
  type        = list(string)
}

variable "private_subnet_cidr_blocks" {
  description = "Private subnet CIDR blocks, one per Availability Zone."
  type        = list(string)
}

variable "enable_nat_gateway" {
  description = "Whether private subnets use a NAT gateway for outbound access."
  type        = bool
}

variable "allowed_alb_ipv4_cidr_blocks" {
  description = "Client IPv4 ranges allowed to reach the ALB."
  type        = set(string)
  default     = ["0.0.0.0/0"]
}

variable "alb_certificate_arn" {
  description = "Optional ACM certificate ARN; when set, HTTP redirects to HTTPS."
  type        = string
  default     = null
}

variable "container_image" {
  description = "Application container image URI."
  type        = string
}

variable "container_port" {
  description = "Application container and target group port."
  type        = number
  default     = 80
}

variable "container_environment" {
  description = "Non-sensitive application environment variables."
  type        = map(string)
  default     = {}
}

variable "container_secrets" {
  description = "Container environment variable names mapped to Secrets Manager secret ARNs."
  type        = map(string)
  default     = {}
}

variable "desired_count" {
  description = "Number of ECS tasks."
  type        = number
}

variable "task_cpu" {
  description = "Fargate task CPU units."
  type        = string
}

variable "task_memory" {
  description = "Fargate task memory in MiB."
  type        = string
}

variable "ecs_log_retention_days" {
  description = "CloudWatch log retention in days."
  type        = number
}

variable "rds_instance_class" {
  description = "RDS MySQL instance class."
  type        = string
}

variable "rds_allocated_storage" {
  description = "Initial RDS storage in GiB."
  type        = number
}

variable "rds_max_allocated_storage" {
  description = "Maximum RDS autoscaling storage in GiB."
  type        = number
}

variable "rds_backup_retention_period" {
  description = "RDS automated backup retention in days."
  type        = number

  validation {
    condition     = var.rds_backup_retention_period >= 1 && var.rds_backup_retention_period <= 35
    error_message = "RDS backup retention must be between 1 and 35 days."
  }
}

variable "rds_deletion_protection" {
  description = "Whether to prevent accidental RDS deletion."
  type        = bool
}

variable "rds_multi_az" {
  description = "Whether to deploy RDS with a standby in another Availability Zone."
  type        = bool
}
