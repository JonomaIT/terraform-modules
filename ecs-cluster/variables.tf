variable "name" {
  type        = string
  description = "Cluster name (e.g. jonomait-stg-ecs)"
}

variable "vpc_id" {
  type        = string
  description = "VPC where the private namespace is created"
}

variable "namespace" {
  type        = string
  description = "Private DNS namespace for service-to-service traffic (e.g. jonomait.internal)"

  validation {
    condition     = endswith(var.namespace, ".internal")
    error_message = "namespace must end in .internal (TLD reserved for private use)."
  }
}

variable "container_insights" {
  type        = string
  description = "Container Insights: enabled, enhanced or disabled (enabled/enhanced incur CloudWatch costs)"
  default     = "enabled"

  validation {
    condition     = contains(["enabled", "enhanced", "disabled"], var.container_insights)
    error_message = "container_insights must be enabled, enhanced or disabled."
  }
}
