output "table_name" {
  description = "Name of the DynamoDB cart table"
  value       = aws_dynamodb_table.cart.name
}

output "table_arn" {
  description = "ARN of the DynamoDB cart table"
  value       = aws_dynamodb_table.cart.arn
}
