variable "project_name" {
  type        = string
  description = "Name of the VPC, used as a prefix for every resource created by this module (e.g. jonomait-stg-network)"
}

variable "cidr" {
  type        = string
  description = "VPC CIDR block (e.g. 10.10.0.0/16)"
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
  description = "Public subnets. Each one gets a NAT Gateway (or only the first one, with single_nat_gateway)"

  validation {
    condition     = length(var.public_subnets) > 0 && length(distinct(var.public_subnets[*].availability_zone)) == length(var.public_subnets)
    error_message = "At least one public subnet, and at most one per availability_zone."
  }
}

variable "single_nat_gateway" {
  type        = bool
  description = "One NAT Gateway for the whole VPC instead of one per AZ. Cheaper (each NAT bills hourly), but private subnets lose internet egress if that AZ fails: fine for labs and non-production"
  default     = false
}

variable "gateway_endpoints" {
  type        = list(string)
  description = "Gateway endpoints on the private route tables (free): s3, dynamodb"
  default     = ["s3", "dynamodb"]

  validation {
    condition     = alltrue([for e in var.gateway_endpoints : contains(["s3", "dynamodb"], e)])
    error_message = "gateway_endpoints accepts s3 and dynamodb (the only gateway endpoints AWS offers)."
  }
}
