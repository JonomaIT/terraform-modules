# ecs-service

**Kind:** pattern. Everything an app needs on ECS from the app contract: task definition, service, IAM roles, logs, autoscaling, Service Connect and, with public hosts, a target group and a host rule on the shared ALB. Finds the cluster, VPC and ALB by naming convention. The task role reads the platform's parameters (`/<prefix>/<env>/platform/*`) and gets the app's data-access policy (`task_policy_arns`).

The design notes are in the comments at the top of the `.tf` files.

<!-- BEGIN_TF_DOCS -->
## Usage

```hcl
# Smallest working use of the ecs-service module. Copy this folder to start: change the values, keep the
# shape. In a real repo, pin the source to a release tag instead of the relative path:
#   source = "git::https://github.com/JonomaIT/terraform-modules.git//ecs-service?ref=ecs-service/vX.Y.Z"

provider "aws" {
  region = "us-east-1"
}

# Finds the cluster, VPC, private subnets and shared ALB by the platform's naming convention
# (<prefix>-<environment>-...), so the platform must already exist in the account.
module "service" {
  source = "../../"

  prefix      = "acme"
  environment = "staging"
  name        = "svc-orders"
  image       = "111111111111.dkr.ecr.us-east-1.amazonaws.com/svc-orders:1.0.0"
  port        = 8080
  hosts       = ["orders"] # orders.<zone> on the shared ALB; leave empty for an internal service

  environment_variables = {
    LOG_LEVEL = "info"
  }
}
```

More in [`examples/`](examples/). Every release of this module is a tag `<module>/vX.Y.Z`, listed in [`CHANGELOG.md`](CHANGELOG.md).

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.10 |
| aws | >= 6.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 6.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| capacity_provider | FARGATE or FARGATE_SPOT (up to ~70% cheaper, tasks may be interrupted: fine for staging and workers) | `string` | `"FARGATE"` | no |
| cpu | Task CPU units (256 = 0.25 vCPU) | `number` | `256` | no |
| cpu_target | Average CPU (%) autoscaling keeps the service at | `number` | `70` | no |
| environment | Account the app runs in (staging, production, shared-services) | `string` | n/a | yes |
| environment_variables | Plain environment variables (never secrets) | `map(string)` | `{}` | no |
| health_check_path | HTTP path the ALB checks (expects 2xx/3xx) | `string` | `"/health"` | no |
| hosts | Public names routed to the app by the shared ALB (they must exist in dns-cloudflare). Empty = internal app, reachable only at <name>.<namespace> | `list(string)` | `[]` | no |
| image | Container image, pinned by tag or digest (never latest) | `string` | n/a | yes |
| max_capacity | Maximum number of tasks (autoscaling on CPU) | `number` | `2` | no |
| memory | Task memory in MiB | `number` | `512` | no |
| min_capacity | Minimum number of tasks (also the initial desired count) | `number` | `1` | no |
| name | App name = repo name (e.g. svc-compras). Also the ECS service and Service Connect name | `string` | n/a | yes |
| port | Port the container listens on | `number` | n/a | yes |
| prefix | Platform prefix (e.g. jonomait): every name starts with <prefix>-<env>-, the platform's parameters live under /<prefix>/<env>/platform and the service namespace is <prefix>.internal | `string` | n/a | yes |
| secrets | Environment variable name => ARN of a Secrets Manager secret or SSM parameter, injected at start | `map(string)` | `{}` | no |
| task_policy_arns | Managed policies attached to the task role: the app's data-access policy (ADR-011). Empty = the app only reads the platform's parameters | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| internal_url | Service-to-service address (Service Connect) |
| log_group | CloudWatch Logs group of the app |
| platform_parameters | Path of the platform's parameters the app can read (e.g. <path>/region-state) |
| public_hosts | Public names routed to the app (empty for internal apps) |
| service_name | ECS service name |
<!-- END_TF_DOCS -->
