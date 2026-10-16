variable "zone" {
  type        = string
  description = "Cloudflare zone (e.g. jonoma.com.br)"
}

variable "hosts" {
  type        = list(string)
  description = "Public names of the app, <label>.<zone> (e.g. api.jonoma.com.br, api-stg.jonoma.com.br)"

  validation {
    condition = alltrue([
      for h in var.hosts : can(regex("^[a-z0-9-]+\\.${replace(var.zone, ".", "\\.")}$", h))
    ])
    error_message = "Every host must be a single label under the zone (<label>.<zone>): Universal SSL covers one level."
  }

  validation {
    condition = alltrue([
      for h in var.hosts : !contains(["ingress", "www"], split(".", h)[0]) && !startswith(h, "ingress-")
    ])
    error_message = "ingress, ingress-* and www are reserved for the platform."
  }
}

variable "target" {
  type        = string
  description = "Entry of the environment the names point to (e.g. ingress.jonoma.com.br)"
}

variable "owner" {
  type        = string
  description = "App that owns the names (the repo name); written in the record comment"
}
