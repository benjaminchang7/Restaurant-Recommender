variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "region" {
  description = "AWS region where resources are deployed"
  type        = string
}

variable "queue_arns" {
  description = "List of ARNs for the SQS queues this role needs access to"
  type        = list(string)
}

variable "namespace" {
  description = "Kubernetes namespace for the service account"
  type        = string
  default     = "default"
}

variable "service_account_name" {
  description = "Name of the Kubernetes service account used for IRSA"
  type        = string
}

variable "oidc_provider" {
  description = "OIDC provider path for IRSA (from EKS)"
  type        = string
}
