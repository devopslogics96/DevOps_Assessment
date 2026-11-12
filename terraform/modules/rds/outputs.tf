output "db_instance_id" {
  description = "ID of the MySQL DB instance."
  value       = aws_db_instance.this.id
}

output "db_endpoint" {
  description = "Hostname and port of the MySQL DB instance."
  value       = aws_db_instance.this.endpoint
}

output "db_address" {
  description = "Hostname of the MySQL DB instance."
  value       = aws_db_instance.this.address
}

output "db_name" {
  description = "Name of the application database."
  value       = aws_db_instance.this.db_name
}

output "master_user_secret_arn" {
  description = "ARN of the Secrets Manager secret containing RDS-managed master credentials."
  value       = try(aws_db_instance.this.master_user_secret[0].secret_arn, null)
}

output "security_group_id" {
  description = "ID of the RDS security group; ingress is restricted to ECS tasks."
  value       = aws_security_group.this.id
}
