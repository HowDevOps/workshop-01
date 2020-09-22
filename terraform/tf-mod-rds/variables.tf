variable "region" {
  default = "eu-central-1"
}

variable "stage" {
  default = "test"
}

variable "instance_type" {
  default = "db.t3.small"
}

variable "deletion_protection" {
  default = false
}

variable "db_engine" {
  default = "mysql"
}

variable "db_engine_version" {
  default = "8.0.20"
}

variable "db_major_engine_version" {
  default = "8.0"
}

variable "db_engine_family" {
  default = "mysql8.0"
}

variable "db_port" {
  default = 3306
}

variable "instance_name" {
  description = "Name of the RDS instance"
  default     = ""
}

variable "db_name" {
  description = "Name of the cluster"
  default     = "main"
}

variable "db_username" {
  default = "root"
}

variable "backup_retention_period" {
  description = "The days to retain backups for"
  default     = 0
}

variable "allocated_storage" {
  default = 5
}