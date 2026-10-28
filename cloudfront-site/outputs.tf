output "bucket" {
  description = "Bucket the deploy uploads the site to"
  value       = aws_s3_bucket.site.id
}

output "failover_bucket" {
  description = "Copy of the bucket in failover_region: the deploy uploads to it too (null without failover)"
  value       = one(aws_s3_bucket.failover[*].id)
}

output "distribution_id" {
  description = "CloudFront distribution (the deploy invalidates its cache)"
  value       = aws_cloudfront_distribution.site.id
}

output "domain_name" {
  description = "CloudFront address the public names point to (app-dns target)"
  value       = aws_cloudfront_distribution.site.domain_name
}
