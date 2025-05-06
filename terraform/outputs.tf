output "eks_cluster_name" {
  description = "EKS Cluster name"
  value       = module.eks.cluster_name
}
output "aurora_endpoint" {
  description = "Aurora PostgreSQL writer endpoint"
  value       = module.aurora.endpoint
}

output "aurora_db_name" {
  description = "Aurora database name"
  value       = module.aurora.db_name
}

output "sqs_queue_urls" {
  value = module.sqs.queue_urls
}

output "aws_account_id" {
  value = data.aws_caller_identity.current.account_id
}
