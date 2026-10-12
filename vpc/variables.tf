variable "project_name" {
  type        = string
  description = "Project name, used as a prefix for every resource created by this module"
}

variable "cidr" {
  type        = string
  description = "VPC CIDR block (e.g. 10.0.0.0/16)"
}

variable "private_subnets" {
  type = list(object({
    name              = string
    cidr              = string
    availability_zone = string
  }))
  description = "Private subnets. Every AZ used here needs a public subnet, which hosts that AZ's NAT Gateway"

  validation {
    condition = alltrue([
      for s in var.private_subnets : contains(var.public_subnets[*].availability_zone, s.availability_zone)
    ])
    error_message = "Every private subnet needs a public subnet in the same availability_zone (it hosts the AZ's NAT Gateway)."
  }
}

variable "public_subnets" {
  type = list(object({
    name              = string
    cidr              = string
    availability_zone = string
  }))
  description = "Public subnets. Each one gets a NAT Gateway, used by the private subnets in the same AZ"

  validation {
    condition     = length(distinct(var.public_subnets[*].availability_zone)) == length(var.public_subnets)
    error_message = "At most one public subnet per availability_zone."
  }
}
