locals {
  effective_image = "${var.image_repository}:${var.image_tag}"
}

resource "kubernetes_deployment" "user_management" {
  metadata {
    name      = "user-management"
    namespace = var.namespace
    labels = {
      app = "user-management"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "user-management"
      }
    }

    template {
      metadata {
        labels = {
          app       = "user-management"
          image-tag = var.image_tag != "" ? var.image_tag : "existing"
        }
      }

      spec {
        container {
          name              = "user-management"
          image             = local.effective_image
          image_pull_policy = "Always"

          port {
            container_port = 8000
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "256Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }

          env_from {
            secret_ref {
              name = "user-management-env"
            }
          }

          env_from {
            secret_ref {
              name = "user-management-aws"
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

resource "kubernetes_service" "user_management" {
  metadata {
    name      = "user-management"
    namespace = var.namespace
    labels = {
      app = "user-management"
    }
  }

  spec {
    selector = {
      app = "user-management"
    }

    port {
      port        = 80
      target_port = 8000
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_horizontal_pod_autoscaler_v2" "user_management_hpa" {
  metadata {
    name      = "user-management"
    namespace = var.namespace
  }

  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment.user_management.metadata[0].name
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

resource "null_resource" "wait_for_ingress" {
  provisioner "local-exec" {
    command = <<EOT
      echo "⏳ Waiting for ingress hostname to be available..."
      for i in {1..30}; do
        HOST=$(kubectl get ingress user-management -n ${var.namespace} -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
        if [ ! -z "$HOST" ]; then
          echo "✅ Ingress hostname is available: $HOST"
          break
        fi
        echo "Attempt $i: Hostname not ready, retrying..."
        sleep 10
      done
    EOT
    interpreter = ["/bin/bash", "-c"]
  }

  depends_on = [kubernetes_deployment.user_management]
}
