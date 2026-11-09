# The site's API (optional): /api/* goes to a Lambda function URL (lambda-function), everything else
# to the bucket. Same host, so the browser needs no CORS and Cloudflare Access can guard /api alone.
#
# The function URL only takes requests signed by this distribution (origin access control, type
# lambda) and only lets this distribution invoke it (the two permissions below). A body sent with
# PUT or POST must come with its SHA-256 in x-amz-content-sha256: CloudFront signs it, not reads it.

locals {
  api = var.api != null
}

resource "aws_cloudfront_origin_access_control" "api" {
  count = local.api ? 1 : 0

  name                              = "${local.full_name}-api"
  description                       = "Lambda origin of ${var.name}"
  origin_access_control_origin_type = "lambda"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# The API is never cached, and gets everything the viewer sent except Host (a function URL answers
# only its own): cookies, query strings and headers, Cloudflare Access's token among them.
data "aws_cloudfront_cache_policy" "disabled" {
  count = local.api ? 1 : 0
  name  = "Managed-CachingDisabled"
}

data "aws_cloudfront_origin_request_policy" "all_viewer" {
  count = local.api ? 1 : 0
  name  = "Managed-AllViewerExceptHostHeader"
}

resource "aws_lambda_permission" "url" {
  count = local.api ? 1 : 0

  statement_id           = "CloudFrontInvokeFunctionUrl"
  action                 = "lambda:InvokeFunctionUrl"
  function_name          = var.api.function_name
  principal              = "cloudfront.amazonaws.com"
  source_arn             = aws_cloudfront_distribution.site.arn
  function_url_auth_type = "AWS_IAM"
}

resource "aws_lambda_permission" "invoke" {
  count = local.api ? 1 : 0

  statement_id             = "CloudFrontInvokeFunction"
  action                   = "lambda:InvokeFunction"
  function_name            = var.api.function_name
  principal                = "cloudfront.amazonaws.com"
  source_arn               = aws_cloudfront_distribution.site.arn
  invoked_via_function_url = true
}

# Single-page app with an API: the app's routes are rewritten to /index.html here, on the bucket's
# behavior only. The distribution-wide error pages (403/404 → index.html) would also turn the API's
# 403s and 404s into the app's HTML.
resource "aws_cloudfront_function" "spa" {
  count = local.api && var.spa ? 1 : 0

  name    = "${local.full_name}-spa"
  runtime = "cloudfront-js-2.0"
  comment = "Routes of ${var.name}: a path without a file extension serves /index.html"
  publish = true
  code    = <<-JS
    function handler(event) {
      var request = event.request;
      if (request.uri.indexOf('.') === -1) request.uri = '/index.html';
      return request;
    }
  JS
}
