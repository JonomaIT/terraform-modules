# Smallest working use of the cloudfront-site module. Copy this folder to start: change the values, keep the
# shape. In a real repo, pin the source to a release tag instead of the relative path:
#   source = "git::https://github.com/JonomaIT/terraform-modules.git//cloudfront-site?ref=cloudfront-site/vX.Y.Z"

provider "aws" {
  region = "us-east-1" # CloudFront only takes ACM certificates from us-east-1
}

provider "cloudflare" {} # token from CLOUDFLARE_API_TOKEN

module "site" {
  source = "../../"

  prefix      = "acme"
  environment = "staging"
  name        = "web-shop"
  zone        = "example.com"
  hosts       = ["shop"] # shop.example.com
  spa         = true     # unknown paths answer index.html (client-side routing)
}
