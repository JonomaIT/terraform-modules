variable "project_name" {
  type        = string
  description = "Nome do projeto. Prefixo de todos os recursos criados (ex: jonomait-ecs)"

  validation {
    condition     = can(regex("^[a-z0-9-]{1,20}$", var.project_name))
    error_message = "project_name deve ter até 20 caracteres, só minúsculas, números e hífen (os nomes de load balancer têm limite de 32)."
  }
}

variable "vpc_id" {
  type        = string
  description = "ID da VPC onde o cluster e os load balancers serão criados"
}

variable "public_subnets" {
  type        = list(string)
  description = "IDs das subnets públicas, usadas pelo load balancer externo"
}

variable "private_subnets" {
  type        = list(string)
  description = "IDs das subnets privadas, usadas pelo load balancer interno e pelo NLB do VPC Link"
}

variable "capacity_providers" {
  type        = list(string)
  description = "Capacity providers do cluster"
  default     = ["FARGATE", "FARGATE_SPOT"]

  validation {
    condition     = contains(var.capacity_providers, "FARGATE")
    error_message = "capacity_providers precisa incluir FARGATE, que é a estratégia padrão do cluster."
  }
}

variable "container_insights" {
  type        = string
  description = "Container Insights do cluster: enabled, enhanced ou disabled (enabled/enhanced geram custo no CloudWatch)"
  default     = "enabled"

  validation {
    condition     = contains(["enabled", "enhanced", "disabled"], var.container_insights)
    error_message = "container_insights deve ser enabled, enhanced ou disabled."
  }
}
