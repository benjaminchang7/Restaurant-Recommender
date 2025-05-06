variable "aws_region" {
  description = "AWS region to deploy to"
  type        = string
  default     = "us-east-1"
}

variable "frontend_origin" {
  description = "Frontend base URL allowed by CORS"
  type        = string
}

variable "jwt_expire_minutes" {
  description = "Number of minutes before the JWT expires"
  type        = number
  default     = 30
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "access_token_expire_minutes" {
  description = "JWT access token expiry in minutes"
  type        = number
  default     = 30
}

variable "google_api_key" {
  type        = string
  description = "Google API key for accessing external services"
}
