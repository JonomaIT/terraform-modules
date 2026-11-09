variable "zone" {
  type        = string
  description = "Cloudflare zone (e.g. jonoma.com.br)"
}

variable "extra_zones" {
  type        = list(string)
  description = "Other zones the platform allows names in (e.g. a customer's own domain): the apex or one label under it"
  default     = []
}

variable "hosts" {
  type        = list(string)
  description = "Public names of the app: <label>.<zone>, the platform zone's apex when zone_owners gives it to this app, or the apex or <label>.<z> of a zone in extra_zones"

  validation {
    condition = alltrue([
      for h in var.hosts : can(regex("^[a-z0-9-]+\\.${replace(var.zone, ".", "\\.")}$", h)) || (h == var.zone && lookup(var.zone_owners, var.zone, "") == var.owner) || anytrue([
        for z in var.extra_zones : h == z || can(regex("^[a-z0-9-]+\\.${replace(z, ".", "\\.")}$", h))
      ])
    ])
    error_message = "Every host must be a single label under the platform's zone (<label>.<zone>: Universal SSL covers one level), the platform zone's apex if zone_owners gives it to this app, or the apex or a single label of a zone in extra_zones."
  }

  validation {
    condition = alltrue([
      for h in var.hosts : !(endswith(h, ".${var.zone}") && (contains(["ingress", "www"], split(".", h)[0]) || startswith(h, "ingress-")))
    ])
    error_message = "ingress, ingress-* and www of the platform's zone are reserved for the platform."
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

variable "zone_owners" {
  type        = map(string)
  description = "Zone => the app that owns it. The platform's zone listed here gives its apex to that app (one-label names stay open to every app); a zone in extra_zones listed here is that app's alone. A zone not listed keeps the old rule (any app)"
  default     = {}
}
