locals {
  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "DevOpsAssessment"
  }
}

module "network" {
  source = "../../modules/network"

  name                         = var.environment
  vpc_cidr_block               = var.vpc_cidr_block
  availability_zones           = var.availability_zones
  public_subnet_cidr_blocks    = var.public_subnet_cidr_blocks
  private_subnet_cidr_blocks   = var.private_subnet_cidr_blocks
  application_port             = var.container_port
  enable_nat_gateway           = var.enable_nat_gateway
  allowed_alb_ipv4_cidr_blocks = var.allowed_alb_ipv4_cidr_blocks
  certificate_arn              = var.alb_certificate_arn
  tags                         = local.tags
}

resource "aws_iam_role" "ecs_execution" {
  name = "${var.environment}-ecs-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "ecs_execution_secrets" {
  count = length(var.container_secrets) == 0 ? 0 : 1

  name = "${var.environment}-ecs-execution-secrets"
  role = aws_iam_role.ecs_execution.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["secretsmanager:GetSecretValue"]
      Resource = distinct(values(var.container_secrets))
    }]
  })
}

resource "aws_iam_role" "ecs_task" {
  name = "${var.environment}-ecs-task"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = local.tags
}

module "ecs" {
  source = "../../modules/ecs"

  depends_on = [
    aws_iam_role_policy_attachment.ecs_execution,
    aws_iam_role_policy.ecs_execution_secrets
  ]

  name                  = var.environment
  vpc_id                = module.network.vpc_id
  alb_security_group_id = module.network.alb_security_group_id
  private_subnet_ids    = module.network.private_subnet_ids
  target_group_arn      = module.network.target_group_arn
  container_image       = var.container_image
  container_port        = var.container_port
  container_environment = var.container_environment
  container_secrets     = var.container_secrets
  desired_count         = var.desired_count
  task_cpu              = var.task_cpu
  task_memory           = var.task_memory
  execution_role_arn    = aws_iam_role.ecs_execution.arn
  task_role_arn         = aws_iam_role.ecs_task.arn
  aws_region            = var.aws_region
  log_retention_days    = var.ecs_log_retention_days
  tags                  = local.tags
}

module "rds" {
  source = "../../modules/rds"

  name                    = var.environment
  vpc_id                  = module.network.vpc_id
  private_subnets         = module.network.private_subnets
  ecs_security_group_id   = module.ecs.task_security_group_id
  instance_class          = var.rds_instance_class
  allocated_storage       = var.rds_allocated_storage
  max_allocated_storage   = var.rds_max_allocated_storage
  backup_retention_period = var.rds_backup_retention_period
  deletion_protection     = var.rds_deletion_protection
  multi_az                = var.rds_multi_az
  tags                    = local.tags
}
