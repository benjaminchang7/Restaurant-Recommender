variable "db_name" {
  type        = string
  description = "Name of the database"
  default     = "restaurant_db"
}

variable "db_user" {
  type        = string
  description = "Master DB user"
  default     = "postgres"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID for the Aurora cluster"
}

variable "subnets" {
  type        = list(string)
  description = "List of subnets for the Aurora DB subnet group"
}

variable "region" {
  type        = string
  description = "AWS region to deploy Aurora"
}

variable "db_password" {
  description = "Password for the Aurora database"
  type        = string
  sensitive   = true
}

variable "db_port" {
  description = "Database port"
  type        = string
  default     = "5432"
}
