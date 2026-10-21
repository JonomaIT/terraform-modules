output "name" {
  description = "Topic name (the same in every region)"
  value       = var.name
}

output "arns" {
  description = "Topic ARN in each region (region => ARN)"
  value       = { for r, t in aws_sns_topic.main : r => t.arn }
}
