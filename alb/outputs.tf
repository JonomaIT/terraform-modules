output "dns_name" {
  description = "ALB DNS name (the origin Cloudflare points to)"
  value       = aws_lb.main.dns_name
}
