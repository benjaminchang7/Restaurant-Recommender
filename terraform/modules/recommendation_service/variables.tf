variable "namespace" {
  type    = string
  default = "default"
}

variable "image_repository" {
  type = string
}

variable "image_tag" {
  type        = string
  description = "Image tag for this service"
  validation {
    condition     = length(var.image_tag) > 0
    error_message = "The image_tag must not be empty."
  }
}
