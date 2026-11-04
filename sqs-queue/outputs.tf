output "name" {
  description = "Queue name (the same in every region)"
  value       = var.name
}

output "urls" {
  description = "Queue URL in each region (region => URL), what the SDKs use"
  value       = { for r, q in aws_sqs_queue.main : r => q.url }
}

output "arns" {
  description = "Queue ARN in each region (region => ARN)"
  value       = { for r, q in aws_sqs_queue.main : r => q.arn }
}

output "standby_urls" {
  description = "Standby queue URL in each region (region => URL); empty without standby"
  value       = { for r, q in aws_sqs_queue.standby : r => q.url }
}

output "standby_arns" {
  description = "Standby queue ARN in each region (region => ARN); empty without standby"
  value       = { for r, q in aws_sqs_queue.standby : r => q.arn }
}

output "dlq_arns" {
  description = "Dead-letter queue ARN in each region (region => ARN)"
  value       = { for r, q in aws_sqs_queue.dlq : r => q.arn }
}
