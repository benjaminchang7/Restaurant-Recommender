variable "name" {
  description = "Name of the Helm release"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace to install into"
  type        = string
  default     = "default"
}

variable "chart" {
  description = "Path to the local Helm chart"
  type        = string
}

variable "image_repository" {
  description = "Docker image repository"
  type        = string
}

variable "image_tag" {
  description = "Docker image tag"
  type        = string
  default     = "latest"
}

variable "depends_on" {
  description = "Dependencies for Helm release"
  type        = list(any)
  default     = []
}
