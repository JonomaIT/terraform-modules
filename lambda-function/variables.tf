variable "prefix" {
  type        = string
  description = "Platform prefix (e.g. jonomait): the function is <prefix>-<env>-<name>-api"

  validation {
    condition     = can(regex("^[a-z][a-z0-9]{1,14}$", var.prefix))
    error_message = "prefix must be 2-15 lowercase letters and digits."
  }
}

variable "environment" {
  type        = string
  description = "Account the function runs in (staging, production, shared-services)"

  validation {
    condition     = contains(["staging", "production", "shared-services"], var.environment)
    error_message = "environment must be staging, production or shared-services."
  }
}

variable "name" {
  type        = string
  description = "App name = repo name (e.g. web-english)"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,30}[a-z0-9]$", var.name))
    error_message = "name must be 3-32 lowercase letters, digits and hyphens."
  }
}

variable "source_dir" {
  type        = string
  description = "Folder with the function's code, zipped as it is (no build step here)"
}

variable "handler" {
  type        = string
  description = "<file>.<function>, e.g. progress.handler for progress.mjs exporting handler"
}

variable "runtime" {
  type        = string
  description = "Lambda runtime"
  default     = "nodejs22.x"

  validation {
    condition     = contains(["nodejs22.x", "python3.13"], var.runtime)
    error_message = "runtime must be nodejs22.x or python3.13 (the runtimes the platform supports)."
  }
}

variable "memory" {
  type        = number
  description = "Memory in MB (CPU grows with it)"
  default     = 128

  validation {
    condition     = var.memory >= 128 && var.memory <= 1024
    error_message = "memory must be 128 to 1024 MB."
  }
}

variable "timeout" {
  type        = number
  description = "Seconds before a call is cut (CloudFront waits 30 s at most)"
  default     = 10

  validation {
    condition     = var.timeout >= 1 && var.timeout <= 30
    error_message = "timeout must be 1 to 30 seconds."
  }
}

variable "environment_variables" {
  type        = map(string)
  description = "Plain environment variables (never secrets)"
  default     = {}
}

variable "policy_arns" {
  type        = list(string)
  description = "Managed policies for the function's role: the app's data-access policy (ADR-011)"
  default     = []
}

variable "log_retention_days" {
  type        = number
  description = "Days the logs are kept"
  default     = 30
}

variable "parameter_paths" {
  type        = list(string)
  description = "SSM parameter paths the function may read, decrypting SecureStrings with the account's aws/ssm key (e.g. /jonomait/production/web-english/secrets): the app's secrets, set outside Terraform"
  default     = []
}
