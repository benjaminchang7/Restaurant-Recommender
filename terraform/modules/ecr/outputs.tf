output "user_management_image_uri" {
  value = aws_ecr_repository.user_management.repository_url
}

output "geo_localization_image_uri" {
  value = aws_ecr_repository.geo_localization_service.repository_url
}

output "recommendation_image_uri" {
  value = aws_ecr_repository.recommendation_service.repository_url
}

output "restaurant_lookup_image_uri" {
  value = aws_ecr_repository.restaurant_lookup_service.repository_url
}
