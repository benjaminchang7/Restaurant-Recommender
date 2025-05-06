resource "aws_ecr_repository" "user_management" {
  name = "user-management-service"

  image_scanning_configuration {
    scan_on_push = true
  }

  image_tag_mutability = "MUTABLE"

  tags = {
    App     = "restaurant-recommendation"
    Service = "user-management"
  }
}

resource "aws_ecr_repository" "geo_localization_service" {
  name = "geo-localization-service"

  image_scanning_configuration {
    scan_on_push = true
  }

  image_tag_mutability = "MUTABLE"

  tags = {
    App     = "restaurant-recommendation"
    Service = "geo_localization_service"
  }
}

resource "aws_ecr_repository" "recommendation_service" {
  name = "recommendation-service"

  image_scanning_configuration {
    scan_on_push = true
  }

  image_tag_mutability = "MUTABLE"

  tags = {
    App     = "restaurant-recommendation"
    Service = "recommendation_service"
  }
}

resource "aws_ecr_repository" "restaurant_lookup_service" {
  name = "restaurant-lookup-service"

  image_scanning_configuration {
    scan_on_push = true
  }

  image_tag_mutability = "MUTABLE"

  tags = {
    App     = "restaurant-recommendation"
    Service = "restaurant_lookup_service"
  }
}