data "aws_subnet" "private" {
  for_each = var.private_subnets

  id = each.value.id
}

resource "aws_db_subnet_group" "this" {
  name        = "${var.name}-db"
  description = "Private database subnets for ${var.name}."
  subnet_ids  = [for subnet in var.private_subnets : subnet.id]

  lifecycle {
    precondition {
      condition     = length(var.private_subnets) >= 2 && length(distinct([for subnet in data.aws_subnet.private : subnet.availability_zone])) >= 2
      error_message = "Provide private subnets in at least two Availability Zones."
    }

    precondition {
      condition     = alltrue([for subnet in data.aws_subnet.private : subnet.vpc_id == var.vpc_id])
      error_message = "All DB subnets must belong to vpc_id."
    }
  }

  tags = merge(var.tags, {
    Name = "${var.name}-db"
  })
}

resource "aws_security_group" "this" {
  name        = "${var.name}-rds"
  description = "Allows MySQL connections only from ECS tasks."
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.name}-rds"
  })
}

resource "aws_vpc_security_group_ingress_rule" "from_ecs" {
  security_group_id            = aws_security_group.this.id
  referenced_security_group_id = var.ecs_security_group_id
  ip_protocol                  = "tcp"
  from_port                    = 3306
  to_port                      = 3306
  description                  = "Allow MySQL only from the ECS task security group."
}

resource "aws_db_instance" "this" {
  identifier                  = "${var.name}-mysql"
  engine                      = "mysql"
  engine_version              = "8.0"
  instance_class              = var.instance_class
  allocated_storage           = var.allocated_storage
  max_allocated_storage       = var.max_allocated_storage
  storage_encrypted           = true
  db_name                     = "app"
  username                    = "dbadmin"
  manage_master_user_password = true
  port                        = 3306
  db_subnet_group_name        = aws_db_subnet_group.this.name
  vpc_security_group_ids      = [aws_security_group.this.id]
  publicly_accessible         = false
  multi_az                    = var.multi_az
  backup_retention_period     = var.backup_retention_period
  deletion_protection         = var.deletion_protection
  skip_final_snapshot         = var.skip_final_snapshot
  final_snapshot_identifier   = var.skip_final_snapshot ? null : "${var.name}-mysql-final"
  auto_minor_version_upgrade  = true
  copy_tags_to_snapshot       = true

  tags = merge(var.tags, {
    Name = "${var.name}-mysql"
  })
}
