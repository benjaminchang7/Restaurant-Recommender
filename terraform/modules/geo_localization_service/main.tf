locals {
  effective_image = "${var.image_repository}:${var.image_tag}"
}

resource "kubernetes_deployment" "geo_localization" {
  metadata {
    name      = "geo-localization"
    namespace = var.namespace
    labels = {
      app = "geo-localization"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "geo-localization"
      }
    }

    template {
      metadata {
        labels = {
          app       = "geo-localization"
          image-tag = var.image_tag != "" ? var.image_tag : "existing"
        }
      }

      spec {
        service_account_name = "microservice-sqs"

        container {
          name              = "geo-localization"
          image             = local.effective_image
          image_pull_policy = "Always"

          port {
            container_port = 8001
          }

          env_from {
            secret_ref {
              name = "user-management-env"
            }
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits ={
              cpu    = "500m"
              memory = "256Mi"
            }
          }
        }
      }
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "kubernetes_service" "geo_localization" {
  metadata {
    name      = "geo-localization"
    namespace = var.namespace
    labels = {
      app = "geo-localization"
    }
  }

  spec {
    selector = {
      app = "geo-localization"
    }

    port {
      port        = 80
      target_port = 8001
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_horizontal_pod_autoscaler_v2" "geo_localization_hpa" {
  metadata {
    name      = "geo-localization"
    namespace = var.namespace
  }

  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment.geo_localization.metadata[0].name
    }

    min_replicas = 1
    max_replicas = 5

    metric {
      type = "Resource"

      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = 70
        }
      }
    }
  }
}
