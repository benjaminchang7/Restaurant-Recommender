data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
}

variable "image_tag" {
  description = "Tag of the Docker image to deploy"
  type        = string
  default     = "latest"
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

resource "random_password" "aurora_password" {
  length  = 20
  special = true
}

resource "random_password" "jwt_secret" {
  length  = 32
  special = true
}

locals {
  public_subnet_map  = { for i, id in module.vpc.public_subnets : "public-${i}" => id }
  private_subnet_map = { for i, id in module.vpc.private_subnets : "private-${i}" => id }
}

module "vpc" {
  source         = "./modules/vpc"
  project_name   = "restaurant-recommendation"
  environment    = "dev"
}

resource "aws_ec2_tag" "public_elb_tags" {
  for_each = local.public_subnet_map
  resource_id = each.value
  key         = "kubernetes.io/role/elb"
  value       = "1"
}

resource "aws_ec2_tag" "cluster_tag_public" {
  for_each = local.public_subnet_map
  resource_id = each.value
  key         = "kubernetes.io/cluster/${module.eks.cluster_name}"
  value       = "shared"
}

resource "aws_ec2_tag" "cluster_tag_private" {
  for_each = local.private_subnet_map
  resource_id = each.value
  key         = "kubernetes.io/cluster/${module.eks.cluster_name}"
  value       = "shared"
}

module "eks" {
  source       = "./modules/eks"
  cluster_name = "restaurant-recommendation-cluster"
  region       = var.aws_region
  vpc_id       = module.vpc.vpc_id
  subnets      = module.vpc.private_subnets
}

module "aurora" {
  source       = "./modules/aurora"
  db_name      = "restaurant_db"
  db_user      = "postgres"
  db_password  = random_password.aurora_password.result
  region       = var.aws_region
  vpc_id       = module.vpc.vpc_id
  subnets      = module.vpc.private_subnets
}

module "sqs" {
  source      = "./modules/sqs"
  region      = var.aws_region
  queue_names = [
    "restaurant-localize-queue",
    "restaurant-lookup-queue",
    "restaurant-recommend-queue"
  ]
}

module "iam" {
  source               = "./modules/iam"
  cluster_name         = module.eks.cluster_name
  region               = var.aws_region
  queue_arns           = values(module.sqs.queue_arns)
  oidc_provider        = module.eks.oidc_provider
  service_account_name = "microservice-sqs"
  namespace            = "default"
}

resource "kubernetes_service_account" "microservice_sqs" {
  metadata {
    name      = "microservice-sqs"
    namespace = "default"
    annotations = {
      "eks.amazonaws.com/role-arn" = module.iam.service_account_role_arn
    }
  }
}


module "secrets" {
  source                 = "./modules/secrets"
  frontend_origin        = var.frontend_origin
  jwt_expire_minutes     = var.jwt_expire_minutes

  db_user                = module.aurora.db_user
  db_name                = module.aurora.db_name
  db_host                = module.aurora.endpoint
  db_port                = module.aurora.port
  db_password            = random_password.aurora_password.result

  jwt_secret             = random_password.jwt_secret.result
  jwt_algorithm          = "HS256"
  iam_role_arn           = module.iam.service_account_role_arn

  aws_region             = var.aws_region

  localize_queue_url     = module.sqs.queue_urls["restaurant-localize-queue"]
  lookup_queue_url       = module.sqs.queue_urls["restaurant-lookup-queue"]
  recommend_queue_url    = module.sqs.queue_urls["restaurant-recommend-queue"]
  google_api_key         = var.google_api_key

  depends_on = [
    module.aurora,
    random_password.aurora_password,
    random_password.jwt_secret
  ]
}



resource "kubernetes_service_account" "alb_controller" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = module.iam.alb_controller_role_arn
    }
  }
}

resource "helm_release" "aws_lb_controller" {
  name       = "aws-load-balancer-controller"
  namespace  = "kube-system"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.7.1"

  values = [
    yamlencode({
      clusterName    = module.eks.cluster_name
      region         = var.aws_region
      serviceAccount = {
        create = false
        name   = "aws-load-balancer-controller"
      }
      vpcId = module.vpc.vpc_id
    })
  ]

  depends_on = [
    kubernetes_service_account.alb_controller,
    module.eks
  ]
}

module "ecr" {
  source = "./modules/ecr"
}

variable "user_management_image_tag" {
  type    = string
  default = ""
}

variable "geo_localization_image_tag" {
  type    = string
  default = ""
}

variable "recommendation_image_tag" {
  type    = string
  default = ""
}

variable "restaurant_lookup_image_tag" {
  type    = string
  default = ""
}


module "user_management_service" {
  source           = "./modules/user_management_service"
  namespace        = "default"
  image_repository = module.ecr.user_management_image_uri
  image_tag        = var.user_management_image_tag
  depends_on       = [module.pgbouncer, module.secrets, helm_release.aws_lb_controller, kubernetes_service_account.microservice_sqs]
}

module "geo_localization_service" {
  source           = "./modules/geo_localization_service"
  namespace        = "default"
  image_repository = module.ecr.geo_localization_image_uri
  image_tag        = var.geo_localization_image_tag
  depends_on       = [module.pgbouncer, module.secrets, helm_release.aws_lb_controller, kubernetes_service_account.microservice_sqs]
}

module "recommendation_service" {
  source           = "./modules/recommendation_service"
  namespace        = "default"
  image_repository = module.ecr.recommendation_image_uri
  image_tag        = var.recommendation_image_tag
  depends_on       = [module.pgbouncer, module.secrets, helm_release.aws_lb_controller, kubernetes_service_account.microservice_sqs]
}

module "restaurant_lookup_service" {
  source           = "./modules/restaurant_lookup_service"
  namespace        = "default"
  image_repository = module.ecr.restaurant_lookup_image_uri
  image_tag        = var.restaurant_lookup_image_tag
  depends_on       = [module.pgbouncer, module.secrets, helm_release.aws_lb_controller, kubernetes_service_account.microservice_sqs]
}

module "pgbouncer" {
  source      = "./modules/pgbouncer"
  db_user     = module.secrets.db_user
  db_password = module.secrets.db_password
  db_host     = module.secrets.db_host
  db_name     = module.secrets.db_name
  namespace   = "default"

  depends_on = [
    module.aurora,
    module.secrets
  ]
}


data "aws_caller_identity" "current" {}
