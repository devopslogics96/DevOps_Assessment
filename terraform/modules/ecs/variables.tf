variable "name" {
  description = "Environment name used as a prefix for ECS resources."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC containing the ECS tasks."
  type        = string
}

variable "alb_security_group_id" {
  description = "Security group ID allowed to connect to the ECS tasks."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs used for Fargate tasks."
  type        = list(string)
}

variable "target_group_arn" {
  description = "ALB target group ARN attached to the ECS service."
  type        = string
}

variable "container_image" {
  description = "Container image URI, including a tag or digest."
  type        = string
}

variable "container_port" {
  description = "TCP port exposed by the application container and target group."
  type        = number

  validation {
    condition     = var.container_port >= 1 && var.container_port <= 65535
    error_message = "The container port must be between 1 and 65535."
  }
}

variable "container_environment" {
  description = "Non-sensitive environment variables passed to the container."
  type        = map(string)
  default     = {}
}

variable "container_secrets" {
  description = "Container environment variable names mapped to Secrets Manager or Systems Manager parameter ARNs."
  type        = map(string)
  default     = {}
}

variable "desired_count" {
  description = "Number of tasks to run."
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

variable "execution_role_arn" {
  description = "IAM task execution role ARN."
  type        = string
}

variable "task_role_arn" {
  description = "IAM role ARN used by application code in the task."
  type        = string
}

variable "aws_region" {
  description = "AWS region used by the CloudWatch Logs configuration."
  type        = string
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days."
  type        = number

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.log_retention_days)
    error_message = "The log retention period must be a value supported by CloudWatch Logs."
  }
}

variable "tags" {
  description = "Tags applied to ECS resources."
  type        = map(string)
  default     = {}
}
