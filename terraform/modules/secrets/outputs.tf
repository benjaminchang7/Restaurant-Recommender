output "db_user" {
  value = var.db_user
}

output "db_password" {
  value     = var.db_password
  sensitive = true
}

output "db_name" {
  value = var.db_name
}

output "db_host" {
  value = var.db_host
}
