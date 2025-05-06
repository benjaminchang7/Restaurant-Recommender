output "cluster_name" {
  description = "EKS Cluster name"
  value       = aws_eks_cluster.this.name
}

output "node_role_arn" {
  description = "IAM role ARN used by EKS worker nodes"
  value       = aws_iam_role.eks_node.arn
}

output "oidc_provider" {
  description = "OIDC provider URL for IRSA-based access"
  value       = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

output "oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.eks.arn
}
