variable "name" {
  type        = string
  description = "Topic name, the same in every region (e.g. jonomait-prd-svc-vendas-pedido-criado)"

  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]{1,256}$", var.name))
    error_message = "name must be 1-256 letters, digits, '_' or '-' (FIFO topics are not supported)."
  }
}

variable "regions" {
  type        = list(string)
  description = "Regions of the app: one topic in each"

  validation {
    condition     = length(var.regions) >= 1 && length(distinct(var.regions)) == length(var.regions)
    error_message = "regions must list at least one region, without repeats."
  }
}
