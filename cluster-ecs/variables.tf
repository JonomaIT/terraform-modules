variable "project_name" {
  type        = string
  description = "Project name, used as a prefix for every resource created (e.g. jonomait-ecs)"

  validation {
    condition     = can(regex("^[a-z0-9-]{1,20}$", var.project_name))
    error_message = "project_name must be up to 20 characters of lowercase letters, digits and hyphens (load balancer names are limited to 32)."
  }
}

variable "vpc_id" {
  type        = string
  description = "ID of the VPC where the cluster and load balancers are created"
}

variable "public_subnets" {
  type        = list(string)
  description = "Public subnet IDs, used by the external load balancer"
}

variable "private_subnets" {
  type        = list(string)
  description = "Private subnet IDs, used by the internal load balancer and the VPC Link NLB"
}

variable "capacity_providers" {
  type        = list(string)
  description = "Cluster capacity providers"
  default     = ["FARGATE", "FARGATE_SPOT"]

  validation {
    condition     = contains(var.capacity_providers, "FARGATE")
    error_message = "capacity_providers must include FARGATE, the cluster's default strategy."
  }
}

variable "container_insights" {
  type        = string
  description = "Cluster Container Insights: enabled, enhanced or disabled (enabled/enhanced incur CloudWatch costs)"
  default     = "enabled"

  validation {
    condition     = contains(["enabled", "enhanced", "disabled"], var.container_insights)
    error_message = "container_insights must be enabled, enhanced or disabled."
  }
}

variable "acm_certs" {
  type        = list(string)
  description = "ACM certificate ARNs for HTTPS on the internal ALB and the NLB. The first one is the listener default; the others are added for SNI. Empty = HTTP only"
  default     = []
}
