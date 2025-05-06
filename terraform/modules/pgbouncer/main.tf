locals {
  pgbouncer_values = templatefile("${path.module}/values.yaml.tpl", {
    DB_HOST     = var.db_host
    DB_NAME     = var.db_name
    DB_USER     = var.db_user
    DB_PASSWORD = var.db_password
  })
}

resource "helm_release" "pgbouncer" {
  name       = "pgbouncer"
  namespace  = "default"
  repository = "https://restaurant-recommendation-hopkins-ep.github.io/pgbouncer-helm/"
  chart      = "pgbouncer"
  version    = "1.2.1"
  values     = [local.pgbouncer_values]
}
