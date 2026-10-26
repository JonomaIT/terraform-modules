variable "name" {
  type        = string
  description = "App name = repo name (e.g. web-sales)"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,30}[a-z0-9]$", var.name))
    error_message = "name must be 3-32 lowercase letters, digits and hyphens."
  }
}

variable "environment" {
  type        = string
  description = "Account the site runs in (staging, production, shared-services)"

  validation {
    condition     = contains(["staging", "production", "shared-services"], var.environment)
    error_message = "environment must be staging, production or shared-services."
  }
}

variable "zone" {
  type        = string
  description = "Cloudflare zone; the platform's *.<zone> certificate (us-east-1) is reused"
}

variable "hosts" {
  type        = list(string)
  description = "Public names of the site (CloudFront aliases), covered by *.<zone>"

  validation {
    condition     = length(var.hosts) > 0
    error_message = "A site needs at least one public name."
  }
}

variable "spa" {
  type        = bool
  description = "Single-page app: unknown paths return index.html with 200"
  default     = false
}

variable "price_class" {
  type        = string
  description = "CloudFront edge locations: PriceClass_100 (US, Canada, Europe; cheapest), _200, _All"
  default     = "PriceClass_100"
}

variable "force_destroy" {
  type        = bool
  description = "Allow destroying the bucket with files in it (labs); keep false where the files matter"
  default     = false
}
