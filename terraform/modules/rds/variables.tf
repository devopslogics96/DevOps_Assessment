variable "name" {
  description = "Environment name used as a prefix for database resources."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC containing the database and ECS tasks."
  type        = string
}

variable "private_subnets" {
  description = "Private subnet IDs and Availability Zones keyed by stable subnet name."
  type = map(object({
    id                = string
    availability_zone = string
  }))
}

variable "ecs_security_group_id" {
  description = "ECS task security group ID allowed to connect to MySQL."
  type        = string
}

variable "instance_class" {
  description = "RDS MySQL instance class."
  type        = string
}

variable "allocated_storage" {
  description = "Initial allocated database storage in GiB."
  type        = number

  validation {
    condition     = var.allocated_storage >= 20
    error_message = "MySQL RDS instances require at least 20 GiB of storage."
  }
}

variable "max_allocated_storage" {
  description = "Maximum storage autoscaling limit in GiB."
  type        = number
}

variable "backup_retention_period" {
  description = "Automated backup retention in days."
  type        = number

  validation {
    condition     = var.backup_retention_period >= 1 && var.backup_retention_period <= 35
    error_message = "Backup retention must be between 1 and 35 days."
  }
}

variable "deletion_protection" {
  description = "Whether to prevent accidental deletion of the DB instance."
  type        = bool
}

variable "multi_az" {
  description = "Whether to deploy a standby DB instance in another Availability Zone."
  type        = bool
}

variable "skip_final_snapshot" {
  description = "Whether to skip a final DB snapshot when the instance is destroyed."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to the DB subnet group, security group, and DB instance."
  type        = map(string)
  default     = {}
}
