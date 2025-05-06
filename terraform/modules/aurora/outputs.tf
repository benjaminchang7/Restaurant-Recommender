output "endpoint" {
  description = "Writer endpoint of the Aurora PostgreSQL cluster"
  value       = aws_rds_cluster.aurora.endpoint
}

output "db_name" {
  description = "Database name configured in the Aurora cluster"
  value       = aws_rds_cluster.aurora.database_name
}

output "db_user" {
  description = "Aurora master username"
  value       = var.db_user
}

output "port" {
  description = "Aurora PostgreSQL port"
  value       = var.db_port
}