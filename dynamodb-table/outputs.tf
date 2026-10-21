output "name" {
  description = "Table name (the same in every region)"
  value       = aws_dynamodb_table.main.name
}

output "arns" {
  description = "Table ARN in each region (region => ARN)"
  value       = { for r in var.regions : r => replace(aws_dynamodb_table.main.arn, ":${var.regions[0]}:", ":${r}:") }
}
