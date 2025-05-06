resource "helm_release" "this" {
  name             = var.name
  namespace        = var.namespace
  chart            = var.chart
  create_namespace = false

  values = [
    yamlencode({
      image = {
        repository = var.image_repository
        tag        = var.image_tag
        pullPolicy = "IfNotPresent"
      }
    })
  ]

  depends_on = var.depends_on
}
