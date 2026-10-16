output "bucket" {
  description = "Bucket the deploy uploads the site to"
  value       = aws_s3_bucket.site.id
}

output "distribution_id" {
  description = "CloudFront distribution (the deploy invalidates its cache)"
  value       = aws_cloudfront_distribution.site.id
}

output "domain_name" {
  description = "CloudFront address the public names point to (app-dns target)"
  value       = aws_cloudfront_distribution.site.domain_name
}
