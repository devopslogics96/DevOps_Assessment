variable "name" {
  description = "Environment name used as a prefix for network resources."
  type        = string
}

variable "vpc_cidr_block" {
  description = "IPv4 CIDR block for the VPC."
  type        = string
}

variable "availability_zones" {
  description = "At least two Availability Zones used for public and private subnets."
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) >= 2 && length(distinct(var.availability_zones)) == length(var.availability_zones)
    error_message = "Provide at least two distinct Availability Zones."
  }
}

variable "public_subnet_cidr_blocks" {
  description = "One public subnet CIDR block per Availability Zone."
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_cidr_blocks) >= 2 && length(var.public_subnet_cidr_blocks) == length(var.availability_zones)
    error_message = "Provide one public subnet CIDR block per Availability Zone, with at least two zones."
  }
}

variable "private_subnet_cidr_blocks" {
  description = "One private subnet CIDR block per Availability Zone."
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_cidr_blocks) >= 2 && length(var.private_subnet_cidr_blocks) == length(var.availability_zones)
    error_message = "Provide one private subnet CIDR block per Availability Zone, with at least two zones."
  }
}

variable "application_port" {
  description = "TCP port exposed by the application target group."
  type        = number

  validation {
    condition     = var.application_port >= 1 && var.application_port <= 65535
    error_message = "The application port must be between 1 and 65535."
  }
}

variable "enable_nat_gateway" {
  description = "Whether to create a single NAT gateway for private subnet egress."
  type        = bool
  default     = true
}

variable "allowed_alb_ipv4_cidr_blocks" {
  description = "IPv4 CIDR blocks allowed to reach the HTTP load balancer."
  type        = set(string)
  default     = ["0.0.0.0/0"]
}

variable "certificate_arn" {
  description = "Optional ACM certificate ARN. When set, the ALB listens on HTTPS and redirects HTTP to HTTPS."
  type        = string
  default     = null

  validation {
    condition     = var.certificate_arn == null || length(trimspace(var.certificate_arn)) > 0
    error_message = "If provided, the ACM certificate ARN must not be empty."
  }
}

variable "tags" {
  description = "Tags applied to network resources."
  type        = map(string)
  default     = {}
}
