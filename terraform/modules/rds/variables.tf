variable "title" {
  description = "Name prefix applied to all resource tags"
  type        = string
  default     = "project-bedrock"
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for the RDS subnet group"
  type        = list(string)
  default     = []
}

variable "vpc_id" {
  description = "ID of the VPC where RDS security groups will be created"
  type        = string
}

variable "mysql_db_name" {
  description = "Name of the MySQL database"
  type        = string
  default     = "catalogdb"
}

variable "postgres_db_name" {
  description = "Name of the PostgreSQL database"
  type        = string
  default     = "ordersdb"
}

variable "db_username" {
  description = "Master username for both RDS instances"
  type        = string
  default     = "dbadmin"
}
