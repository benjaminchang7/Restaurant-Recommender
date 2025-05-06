# Namespace to create the secrets in
variable "namespace" {
  description = "Kubernetes namespace for secrets"
  type        = string
  default     = "default"
}

# --- Database Configuration ---
variable "db_user" {
  description = "Database username"
  type        = string
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "Name of the database"
  type        = string
}

variable "db_host" {
  description = "Hostname or endpoint of the database"
  type        = string
}

variable "db_port" {
  description = "Port the database listens on"
  type        = string
  default     = "5432"
}

# --- JWT Configuration ---
variable "jwt_secret" {
  description = "Secret key used to sign JWTs"
  type        = string
  sensitive   = true
}

variable "jwt_algorithm" {
  description = "JWT signing algorithm"
  type        = string
  default     = "HS256"
}

variable "jwt_expire_minutes" {
  description = "Access token expiration time in minutes"
  type        = number
  default     = 30
}

# --- IAM Integration ---
variable "iam_role_arn" {
  description = "IAM role ARN for IRSA (used in application pod)"
  type        = string
}

# --- Frontend CORS Configuration ---
variable "frontend_origin" {
  description = "Frontend base URL allowed by CORS"
  type        = string
}

variable "localize_queue_url" {
  type        = string
  description = "URL of the SQS queue for localization"
}

variable "aws_region" {
  type        = string
  description = "AWS region for boto3 client"
}

variable "lookup_queue_url" {
  type        = string
  description = "URL of the restaurant-lookup-queue"
}

variable "recommend_queue_url" {
  type        = string
  description = "URL of the restaurant-recommend-queue"
}

variable "google_api_key" {
  type        = string
  description = "Api key for google"
}