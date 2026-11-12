locals {
  public_subnets = {
    for index, cidr_block in var.public_subnet_cidr_blocks :
    "public-${index + 1}" => {
      cidr_block        = cidr_block
      availability_zone = try(var.availability_zones[index], null)
    }
  }

  private_subnets = {
    for index, cidr_block in var.private_subnet_cidr_blocks :
    "private-${index + 1}" => {
      cidr_block        = cidr_block
      availability_zone = try(var.availability_zones[index], null)
    }
  }

  alb_ingress_rules = {
    for pair in setproduct(
      var.allowed_alb_ipv4_cidr_blocks,
      var.certificate_arn == null ? toset([80]) : toset([80, 443])
      ) : "${pair[0]}-${pair[1]}" => {
      cidr = pair[0]
      port = pair[1]
    }
  }
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, {
    Name = "${var.name}-vpc"
  })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.name}-igw"
  })
}

resource "aws_subnet" "public" {
  for_each = local.public_subnets

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "${var.name}-${each.key}"
    Tier = "public"
  })
}

resource "aws_subnet" "private" {
  for_each = local.private_subnets

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = false

  tags = merge(var.tags, {
    Name = "${var.name}-${each.key}"
    Tier = "private"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(var.tags, {
    Name = "${var.name}-public"
  })
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.name}-private"
  })
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}

resource "aws_eip" "nat" {
  count  = var.enable_nat_gateway ? 1 : 0
  domain = "vpc"

  tags = merge(var.tags, {
    Name = "${var.name}-nat"
  })
}

resource "aws_nat_gateway" "this" {
  count = var.enable_nat_gateway ? 1 : 0

  allocation_id = aws_eip.nat[0].id
  subnet_id     = try(aws_subnet.public["public-1"].id, null)

  depends_on = [
    aws_internet_gateway.this,
    aws_route_table_association.public
  ]

  tags = merge(var.tags, {
    Name = "${var.name}-nat"
  })
}

resource "aws_route" "private_nat" {
  count = var.enable_nat_gateway ? 1 : 0

  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[0].id
}

resource "aws_security_group" "alb" {
  name        = "${var.name}-alb"
  description = "Allows HTTP client traffic to the application load balancer."
  vpc_id      = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.name}-alb"
  })
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  for_each = local.alb_ingress_rules

  security_group_id = aws_security_group.alb.id
  ip_protocol       = "tcp"
  from_port         = each.value.port
  to_port           = each.value.port
  cidr_ipv4         = each.value.cidr
  description       = "Allow TCP ${each.value.port} from ${each.value.cidr}."
}

resource "aws_vpc_security_group_egress_rule" "alb_to_targets" {
  security_group_id = aws_security_group.alb.id
  ip_protocol       = "-1"
  cidr_ipv4         = var.vpc_cidr_block
  description       = "Allow load balancer traffic to VPC targets."
}

resource "aws_lb" "this" {
  name               = substr("${var.name}-alb", 0, 32)
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [for subnet in aws_subnet.public : subnet.id]

  tags = merge(var.tags, {
    Name = "${var.name}-alb"
  })
}

resource "aws_lb_target_group" "app" {
  name        = substr("${var.name}-app", 0, 32)
  port        = var.application_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.this.id

  health_check {
    enabled             = true
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = var.tags
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = var.certificate_arn == null ? "forward" : "redirect"

    target_group_arn = var.certificate_arn == null ? aws_lb_target_group.app.arn : null

    dynamic "redirect" {
      for_each = var.certificate_arn == null ? [] : [var.certificate_arn]

      content {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }
}

resource "aws_lb_listener" "https" {
  count = var.certificate_arn == null ? 0 : 1

  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = var.certificate_arn
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}
