# The app contract (deploy/app.hcl + deploy/env/<account>.tfvars). Everything else (cluster, ALB,
# VPC, subnets, namespace) is found by naming convention, so an app never passes an ID.

variable "name" {
  type        = string
  description = "App name = repo name (e.g. svc-compras). Also the ECS service and Service Connect name"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,30}[a-z0-9]$", var.name))
    error_message = "name must be 3-32 lowercase letters, digits and hyphens."
  }
}

variable "environment" {
  type        = string
  description = "Account the app runs in (staging, production, shared-services)"

  validation {
    condition     = contains(["staging", "production", "shared-services"], var.environment)
    error_message = "environment must be staging, production or shared-services."
  }
}

variable "image" {
  type        = string
  description = "Container image, pinned by tag or digest (never latest)"

  validation {
    condition     = !endswith(var.image, ":latest") && strcontains(var.image, ":") || strcontains(var.image, "@sha256:")
    error_message = "image must be pinned by tag or digest, and never :latest."
  }
}

variable "port" {
  type        = number
  description = "Port the container listens on"
}

variable "hosts" {
  type        = list(string)
  description = "Public names routed to the app by the shared ALB (they must exist in dns-cloudflare). Empty = internal app, reachable only at <name>.<namespace>"
  default     = []
}

variable "cpu" {
  type        = number
  description = "Task CPU units (256 = 0.25 vCPU)"
  default     = 256
}

variable "memory" {
  type        = number
  description = "Task memory in MiB"
  default     = 512
}

variable "min_capacity" {
  type        = number
  description = "Minimum number of tasks (also the initial desired count)"
  default     = 1
}

variable "max_capacity" {
  type        = number
  description = "Maximum number of tasks (autoscaling on CPU)"
  default     = 2

  validation {
    condition     = var.max_capacity >= var.min_capacity
    error_message = "max_capacity must be >= min_capacity."
  }
}

variable "cpu_target" {
  type        = number
  description = "Average CPU (%) autoscaling keeps the service at"
  default     = 70
}

variable "health_check_path" {
  type        = string
  description = "HTTP path the ALB checks (expects 2xx/3xx)"
  default     = "/health"
}

variable "environment_variables" {
  type        = map(string)
  description = "Plain environment variables (never secrets)"
  default     = {}
}

variable "secrets" {
  type        = map(string)
  description = "Environment variable name => ARN of a Secrets Manager secret or SSM parameter, injected at start"
  default     = {}
}

variable "capacity_provider" {
  type        = string
  description = "FARGATE or FARGATE_SPOT (up to ~70% cheaper, tasks may be interrupted: fine for staging and workers)"
  default     = "FARGATE"

  validation {
    condition     = contains(["FARGATE", "FARGATE_SPOT"], var.capacity_provider)
    error_message = "capacity_provider must be FARGATE or FARGATE_SPOT."
  }
}
