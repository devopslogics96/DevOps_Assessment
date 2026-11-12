output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs."
  value       = [for subnet in aws_subnet.public : subnet.id]
}

output "private_subnet_ids" {
  description = "Private subnet IDs."
  value       = [for subnet in aws_subnet.private : subnet.id]
}

output "private_subnets" {
  description = "Private subnet IDs and Availability Zones keyed by subnet name."
  value = {
    for name, subnet in aws_subnet.private : name => {
      id                = subnet.id
      availability_zone = subnet.availability_zone
    }
  }
}

output "alb_security_group_id" {
  description = "ID of the ALB security group."
  value       = aws_security_group.alb.id
}

output "alb_dns_name" {
  description = "Public DNS name of the application load balancer."
  value       = aws_lb.this.dns_name
}

output "alb_zone_id" {
  description = "Route 53 hosted zone ID of the load balancer."
  value       = aws_lb.this.zone_id
}

output "target_group_arn" {
  description = "ARN of the application target group."
  value       = aws_lb_target_group.app.arn
}

output "load_balancer_url" {
  description = "URL of the load balancer, using HTTPS when a certificate is configured."
  value       = "${var.certificate_arn == null ? "http" : "https"}://${aws_lb.this.dns_name}"
}
