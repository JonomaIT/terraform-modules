output "function_name" {
  description = "Lambda function"
  value       = aws_lambda_function.this.function_name
}

output "function_arn" {
  description = "Lambda function ARN"
  value       = aws_lambda_function.this.arn
}

output "url_domain" {
  description = "Host of the function URL: the origin of the API in CloudFront"
  value       = trimsuffix(trimprefix(aws_lambda_function_url.this.function_url, "https://"), "/")
}

output "role_name" {
  description = "The function's role"
  value       = aws_iam_role.function.name
}
