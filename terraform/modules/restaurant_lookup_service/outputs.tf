output "service_name" {
  value       = length(kubernetes_service.restaurant_lookup) > 0 ? kubernetes_service.restaurant_lookup.metadata[0].name : null
  description = "Name of the restaurant lookup service"
}
