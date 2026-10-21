variable "name" {
  type        = string
  description = "Table name, the same in every region (e.g. jonomait-prd-svc-vendas-pedidos)"

  validation {
    condition     = can(regex("^[a-zA-Z0-9_.-]{3,255}$", var.name))
    error_message = "name must be 3-255 letters, digits, '_', '-' or '.'."
  }
}

variable "regions" {
  type        = list(string)
  description = "Regions of the app, primary first: the table lives in the first one and every other one gets a replica"

  validation {
    condition     = length(var.regions) >= 1 && length(distinct(var.regions)) == length(var.regions)
    error_message = "regions must list at least one region, without repeats."
  }
}

variable "hash_key" {
  type        = string
  description = "Partition key attribute"
}

variable "hash_key_type" {
  type        = string
  description = "Type of the partition key: S (string), N (number) or B (binary)"
  default     = "S"

  validation {
    condition     = contains(["S", "N", "B"], var.hash_key_type)
    error_message = "hash_key_type must be S, N or B."
  }
}

variable "range_key" {
  type        = string
  description = "Sort key attribute (null = partition key only)"
  default     = null
}

variable "range_key_type" {
  type        = string
  description = "Type of the sort key: S, N or B"
  default     = "S"

  validation {
    condition     = contains(["S", "N", "B"], var.range_key_type)
    error_message = "range_key_type must be S, N or B."
  }
}

variable "ttl_attribute" {
  type        = string
  description = "Attribute holding an expiry time (Unix seconds): DynamoDB deletes expired items for free (null = no TTL)"
  default     = null
}

variable "point_in_time_recovery" {
  type        = bool
  description = "Continuous backups: restore the table to any second of the last 35 days"
  default     = true
}

variable "deletion_protection" {
  type        = bool
  description = "Refuse to delete the table (and its replicas). Only labs turn it off, to be destroyed at the end of the day"
  default     = true
}
