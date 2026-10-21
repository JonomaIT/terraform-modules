output "names" {
  description = "Bucket name in each region (region => name)"
  value       = { for r, b in aws_s3_bucket.main : r => b.bucket }
}

output "arns" {
  description = "Bucket ARN in each region (region => ARN)"
  value       = { for r, b in aws_s3_bucket.main : r => b.arn }
}
