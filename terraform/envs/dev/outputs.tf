output "application_url" {
  description = "Public application URL."
  value       = module.network.load_balancer_url
}

output "rds_endpoint" {
  description = "Private MySQL endpoint; reachable only from ECS tasks."
  value       = module.rds.db_endpoint
}

output "rds_master_secret_arn" {
  description = "Secrets Manager ARN for RDS-managed master credentials."
  value       = module.rds.master_user_secret_arn
}

output "ecs_cluster_arn" {
  description = "ECS cluster ARN."
  value       = module.ecs.cluster_arn
}
