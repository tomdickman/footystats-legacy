variable "pg_host" {
  description = "Postgres Database Host"
  type        = string
  sensitive   = true
}

variable "pg_database" {
  description = "Postgres Database"
  type        = string
  sensitive   = true
}

variable "pg_password" {
  description = "Postgres Password"
  type        = string
  sensitive   = true
}

variable "pg_port" {
  description = "Postgres Port"
  type        = string
  sensitive   = true
}

variable "pg_user" {
  description = "Postgres User"
  type        = string
  sensitive   = true
}
