output "service_account_role_arn" {
  description = "ARN of the IAM role for Kubernetes service account (SQS access)"
  value       = aws_iam_role.service_account_role.arn
}

output "alb_controller_role_arn" {
  description = "ARN of the IAM role for the AWS Load Balancer Controller"
  value       = aws_iam_role.alb_controller.arn
}

output "github_actions_access_key_id" {
  description = "Access key ID for GitHub Actions user"
  value       = aws_iam_access_key.github_actions.id
}

output "github_actions_secret_access_key" {
  description = "Secret access key for GitHub Actions user (sensitive)"
  value       = aws_iam_access_key.github_actions.secret
  sensitive   = true
}
