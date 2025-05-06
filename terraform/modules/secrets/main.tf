# App Environment Variables for User Management Service
resource "kubernetes_secret" "app_env" {
  metadata {
    name      = "user-management-env"
    namespace = var.namespace
  }

  data = {
    DB_USER                      = var.db_user
    DB_PASSWORD                  = var.db_password
    DB_NAME                      = var.db_name
    DB_HOST                      = var.db_host
    DB_PORT                      = var.db_port
    SECRET_KEY                   = var.jwt_secret
    ALGORITHM                    = var.jwt_algorithm
    FRONTEND_ORIGIN              = var.frontend_origin
    ACCESS_TOKEN_EXPIRE_MINUTES = tostring(var.jwt_expire_minutes)

    LOCALIZE_QUEUE_URL           = var.localize_queue_url
    LOOKUP_QUEUE_URL             = var.lookup_queue_url
    RECOMMEND_QUEUE_URL          = var.recommend_queue_url
    AWS_REGION                   = var.aws_region
    GOOGLE_API_KEY               = var.google_api_key
  }

  type = "Opaque"
}

resource "kubernetes_secret" "pgbouncer_env" {
  metadata {
    name      = "pgbouncer-env"
    namespace = var.namespace
  }

  data = {
    POSTGRESQL_USERNAME = var.db_user
    POSTGRESQL_PASSWORD = var.db_password
    POSTGRESQL_HOST     = var.db_host
    POSTGRESQL_PORT     = var.db_port
    POSTGRESQL_DATABASE = var.db_name
  }

  type = "Opaque"
}



# IRSA IAM Role Secret (e.g., for mounting into Pod env)
resource "kubernetes_secret" "aws_iam" {
  metadata {
    name      = "user-management-aws"
    namespace = var.namespace
  }

  data = {
    iamRoleArn = var.iam_role_arn
  }

  type = "Opaque"
}
