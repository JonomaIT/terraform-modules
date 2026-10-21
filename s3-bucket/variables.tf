variable "name" {
  type        = string
  description = "Base name; each region's bucket is <name>-<region> (e.g. jonomait-prd-svc-vendas-arquivo-sa-east-1)"

  # 63 characters at most per bucket, minus the longest region suffix (-ap-southeast-1).
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,46}[a-z0-9]$", var.name))
    error_message = "name must be 3-48 lowercase letters, digits and hyphens (the region is appended)."
  }
}

variable "regions" {
  type        = list(string)
  description = "Regions of the app: one bucket in each"

  validation {
    condition     = length(var.regions) >= 1 && length(distinct(var.regions)) == length(var.regions)
    error_message = "regions must list at least one region, without repeats."
  }
}

variable "replicate" {
  type        = bool
  description = "Copy every object to the other regions' buckets, in both directions (no effect with one region)"
  default     = true
}

variable "noncurrent_days" {
  type        = number
  description = "Days an overwritten or deleted object version is kept before it expires"
  default     = 30

  validation {
    condition     = var.noncurrent_days >= 1
    error_message = "noncurrent_days must be at least 1."
  }
}

variable "force_destroy" {
  type        = bool
  description = "Allow destroying the buckets with objects inside. Only labs turn it on"
  default     = false
}
