variable "name" {
  type        = string
  description = "Queue name, the same in every region (the dead-letter queue is <name>-dlq)"

  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]{1,76}$", var.name))
    error_message = "name must be 1-76 letters, digits, '_' or '-' (80 with the -dlq suffix; FIFO queues are not supported)."
  }
}

variable "regions" {
  type        = list(string)
  description = "Regions of the app: one queue (and dead-letter queue) in each"

  validation {
    condition     = length(var.regions) >= 1 && length(distinct(var.regions)) == length(var.regions)
    error_message = "regions must list at least one region, without repeats."
  }
}

variable "visibility_timeout" {
  type        = number
  description = "Seconds a received message stays hidden from other consumers; longer than the processing of one message"
  default     = 60

  validation {
    condition     = var.visibility_timeout >= 0 && var.visibility_timeout <= 43200
    error_message = "visibility_timeout must be 0-43200 seconds."
  }
}

variable "retention_days" {
  type        = number
  description = "Days an unprocessed message is kept. Covers how long a region can stay passive or down and still process its backlog"
  default     = 4

  validation {
    condition     = var.retention_days >= 1 && var.retention_days <= 14
    error_message = "retention_days must be 1-14."
  }
}

variable "max_receive_count" {
  type        = number
  description = "Failed receives before a message moves to the dead-letter queue"
  default     = 5

  validation {
    condition     = var.max_receive_count >= 1 && var.max_receive_count <= 1000
    error_message = "max_receive_count must be 1-1000."
  }
}

variable "subscribe_topic_arns" {
  type        = list(string)
  description = "SNS topics (any region of the account) whose messages every queue receives"
  default     = []

  validation {
    condition     = alltrue([for a in var.subscribe_topic_arns : can(regex("^arn:aws:sns:[a-z0-9-]+:[0-9]{12}:[a-zA-Z0-9_-]+$", a))])
    error_message = "subscribe_topic_arns must be SNS topic ARNs."
  }
}
