variable "name" {
  type        = string
  description = "App name = repo name (e.g. web-sales)"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,30}[a-z0-9]$", var.name))
    error_message = "name must be 3-32 lowercase letters, digits and hyphens."
  }
}

variable "prefix" {
  type        = string
  description = "Platform prefix (e.g. jonomait): every name starts with <prefix>-<env>-, the platform's parameters live under /<prefix>/<env>/platform"

  validation {
    condition     = can(regex("^[a-z][a-z0-9]{1,14}$", var.prefix))
    error_message = "prefix must be 2-15 lowercase letters and digits (it starts names that have length limits)."
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
  description = "The platform's Cloudflare zone; its *.<zone> certificate (us-east-1) covers one-label names under it"
}

variable "extra_zones" {
  type        = list(string)
  description = "Other Cloudflare zones the platform allows names in (e.g. a customer's own domain). A site with a name there gets a certificate of its own, validated in Cloudflare"
  default     = []
}

variable "hosts" {
  type        = list(string)
  description = "Public names of the site (CloudFront aliases): one label under zone, or names in extra_zones"

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

variable "failover_region" {
  type        = string
  description = "Region of a replica of the bucket, read by CloudFront when the primary bucket fails (origin failover). null = one bucket"
  default     = null
}

variable "force_destroy" {
  type        = bool
  description = "Allow destroying the bucket with files in it (labs); keep false where the files matter"
  default     = false
}

variable "zone_owners" {
  type        = map(string)
  description = "Zone => the app that owns it. The platform's zone listed here gives its apex to that app (one-label names stay open to every app); a zone in extra_zones listed here is that app's alone. A zone not listed keeps the old rule (any app)"
  default     = {}
}
