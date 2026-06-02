output "mysql_endpoint" {
  description = "Connection endpoint for the MySQL RDS instance"
  value       = aws_db_instance.mysql.endpoint
}

output "postgres_endpoint" {
  description = "Connection endpoint for the PostgreSQL RDS instance"
  value       = aws_db_instance.postgres.endpoint
}

output "mysql_secret_arn" {
  description = "ARN of the Secrets Manager secret holding MySQL credentials"
  value       = aws_secretsmanager_secret.mysql.arn
}

output "postgres_secret_arn" {
  description = "ARN of the Secrets Manager secret holding PostgreSQL credentials"
  value       = aws_secretsmanager_secret.postgres.arn
}
