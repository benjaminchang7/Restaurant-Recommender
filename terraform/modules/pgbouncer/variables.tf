variable "db_host" {
  description = "Hostname of the Aurora PostgreSQL database"
  type        = string
}

variable "db_name" {
  description = "Name of the PostgreSQL database"
  type        = string
}

variable "db_user" {
  description = "Database username"
  type        = string
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "namespace" {
  description = "Kubernetes namespace for PgBouncer"
  type        = string
  default     = "default"
}
