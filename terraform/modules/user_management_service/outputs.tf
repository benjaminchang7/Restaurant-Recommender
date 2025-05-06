output "ingress_hostname" {
  value       = try(kubernetes_ingress_v1.user_management.status[0].load_balancer[0].ingress[0].hostname, null)
  description = "Ingress ALB DNS for user management service"
}
