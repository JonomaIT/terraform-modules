variable "project_name" {
  type        = string
  description = "Nome do projeto. Essa variável será um prefixo para os recursos criados dentro desse projeto"
}

variable "cidr" {
  type        = string
  description = "Bloco CIDR da VPC (ex: 10.0.0.0/16)"
}

variable "private_subnets" {
  type = list(object({
    name              = string
    cidr              = string
    availability_zone = string
  }))
  description = "Subnets privadas. Cada AZ usada aqui precisa ter uma subnet pública, onde fica o NAT Gateway dela"

  validation {
    condition = alltrue([
      for s in var.private_subnets : contains(var.public_subnets[*].availability_zone, s.availability_zone)
    ])
    error_message = "Toda subnet privada precisa de uma subnet pública na mesma availability_zone (é onde fica o NAT Gateway da AZ)."
  }
}

variable "public_subnets" {
  type = list(object({
    name              = string
    cidr              = string
    availability_zone = string
  }))
  description = "Subnets públicas. Cada uma recebe um NAT Gateway, usado pelas subnets privadas da mesma AZ"

  validation {
    condition     = length(distinct(var.public_subnets[*].availability_zone)) == length(var.public_subnets)
    error_message = "No máximo uma subnet pública por availability_zone."
  }
}
