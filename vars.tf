variable "POSTGRES_DB" {
  description = "Nome do banco de dados PostgreSQL"
  type        = string
}

variable "POSTGRES_USER" {
  description = "Usuário do banco de dados PostgreSQL"
  type        = string
}

variable "POSTGRES_PASSWORD" {
  description = "Senha do banco de dados PostgreSQL"
  type        = string
  sensitive   = true
}

variable "PORT" {
  description = "Porta da aplicação"
  type        = number
}

variable "DB_PORT" {
  description = "Porta para o banco de dados PostgreSQL"
  type        = number
}

variable "HOST" {
  description = "Hostname para o banco de dados PostgreSQL"
  type        = string
}
