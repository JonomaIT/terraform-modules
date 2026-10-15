variable "name" {
  type        = string
  description = "ALB name (e.g. jonomait-stg-alb-shared); also the security group prefix"

  validation {
    condition     = can(regex("^[a-z0-9-]{1,32}$", var.name)) && !startswith(var.name, "internal-")
    error_message = "name must be up to 32 lowercase letters, digits and hyphens, and cannot start with internal-."
  }
}

variable "vpc_id" {
  type        = string
  description = "VPC of the ALB"
}

variable "subnets" {
  type        = list(string)
  description = "Public subnet IDs (at least two AZs)"

  validation {
    condition     = length(var.subnets) >= 2
    error_message = "An ALB needs subnets in at least two availability zones."
  }
}

variable "certificate_arn" {
  type        = string
  description = "ACM certificate of the HTTPS listener (validated, in the ALB's region)"
}

variable "ingress_cidrs" {
  type        = list(string)
  description = "Sources allowed on port 443, e.g. Cloudflare's IP ranges so traffic only comes through Cloudflare"

  validation {
    condition     = length(var.ingress_cidrs) > 0 && alltrue([for c in var.ingress_cidrs : can(cidrnetmask(c))])
    error_message = "ingress_cidrs needs at least one valid IPv4 CIDR."
  }
}

variable "deletion_protection" {
  type        = bool
  description = "Refuse to delete the ALB (true in production)"
  default     = false
}
