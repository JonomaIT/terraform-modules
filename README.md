# terraform-modules

Terraform module library for JonomaIT. Modules describe **how** to build things; what actually exists, in which account and region, is decided by the [`infrastructure`](https://github.com/JonomaIT/infrastructure) repo (platform) and by the app runner in [`pipelines`](https://github.com/JonomaIT/pipelines).

## Modules

| Module | Kind | What it creates |
|---|---|---|
| [`vpc`](vpc/) | primitive | VPC, public and private subnets (tagged `Tier = public \| private`), Internet Gateway, NAT Gateway per AZ or a single one (`single_nat_gateway`). |
| [`ecs-cluster`](ecs-cluster/) | primitive | ECS cluster (Fargate and Fargate Spot) and the private namespace for service-to-service names (`<app>.jonomait.internal`, ECS Service Connect). |
| [`alb`](alb/) | primitive | Shared internet-facing ALB: HTTPS only (no port 80, fail closed), only from `ingress_cidrs` (Cloudflare's ranges), default answer `404 <name> (<region>)`. |
| [`ecs-service`](ecs-service/) | **pattern** | Everything an app needs on ECS from the app contract: task definition, service, IAM roles, logs, autoscaling, Service Connect and, with public hosts, a target group and a host rule on the shared ALB. Finds the cluster, VPC and ALB by naming convention. |

**Primitive vs pattern:** the platform assembles primitives once per account and region; apps consume patterns, which wrap everything so an app only fills in values.

## Usage

Always pin a SemVer tag, never a branch:

```hcl
module "vpc" {
  source = "git::https://github.com/JonomaIT/terraform-modules.git//vpc?ref=v0.6.1"

  project_name       = "jonomait-stg-network"
  cidr               = "10.10.0.0/16"
  single_nat_gateway = true
  public_subnets     = [{ name = "public-a", cidr = "10.10.48.0/24", availability_zone = "us-east-1a" }, ...]
  private_subnets    = [{ name = "private-a", cidr = "10.10.0.0/20", availability_zone = "us-east-1a" }, ...]
}
```

A tag versions the whole repo: `v0.6.0` applies to every module.

## Module rules

- Modules never declare a `provider` or a `backend`: the caller provides both.
- `versions.tf` sets the minimum Terraform and AWS provider versions.
- Every `variable` has a `type` and a `description`; every `output` has a `description`.
- Nothing hard-coded: region, account, AZs and IDs come from variables or data sources. Patterns follow the naming convention (`jonomait-<env>-<component>`) to find what the platform already runs.
- Validations live on the variable, so errors show up at `plan` time instead of halfway through an `apply`.
- Every module has `tests/` (terraform test with a mocked provider). CI runs fmt, validate and the tests of every module.

## Tests

```bash
cd ecs-service
terraform init -backend=false
terraform test
```

## Versions

| Tag | Change |
|---|---|
| `v0.6.1` | Security scan exceptions, annotated in the code: `alb` public on purpose (Cloudflare in front, 443 only from its ranges), `ecs-service` egress open through NAT (until VPC endpoints or an egress proxy). No resource changes. |
| `v0.6.0` | **New layout (ADR-008, ADR-009).** `cluster-ecs` is removed and split into `ecs-cluster` (cluster + namespace) and `alb` (shared public ALB locked to Cloudflare, HTTPS only); the internal ALB, NLB, VPC Link and Global Accelerator path are gone. New `ecs-service` pattern. `vpc`: `single_nat_gateway`, `Tier` tags on subnets and route tables, `vpc_cidr` and `nat_gateway_count` outputs. Tests for every module. The previous modules stay available at `v0.5.1`. |
| `v0.5.1` | `cluster-ecs`: destroy no longer fails with `ResourceInUse` on the internal ALB listeners. |
| `v0.5.0` | `cluster-ecs`: `ingress_ports`. |
| `v0.4.0` | `cluster-ecs`: `ingress_cidrs`, optional external ALB. |
| `v0.3.1` | `cluster-ecs`: internal ALB accepts traffic preserved by the NLB. |
| `v0.3.0` | `cluster-ecs`: Global Accelerator support, optional HTTPS. |
| `v0.2.0` | `cluster-ecs` module. |
| `v0.1.0` | `vpc` module. |
