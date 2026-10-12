# terraform-modules

Terraform module library for JonomaIT. Modules describe **how** to build things; what actually exists is decided by the [`infrastructure`](https://github.com/JonomaIT/infrastructure) repo.

## Modules

| Module | What it creates |
|---|---|
| [`vpc`](vpc/) | VPC with public subnets (Internet Gateway) and private subnets, with one NAT Gateway per AZ. |
| [`cluster-ecs`](cluster-ecs/) | ECS cluster (Fargate and Fargate Spot), external ALB, internal ALB, private zone `<project>.internal`, Cloud Map namespaces (service discovery and Service Connect) and an API Gateway VPC Link through an NLB. |

## Usage

Always pin a SemVer tag, never a branch:

```hcl
module "vpc" {
  source = "git::https://github.com/JonomaIT/terraform-modules.git//vpc?ref=v0.3.0"

  project_name    = "example"
  cidr            = "10.0.0.0/16"
  public_subnets  = [{ name = "public-1a", cidr = "10.0.48.0/24", availability_zone = "us-east-1a" }]
  private_subnets = [{ name = "private-1a", cidr = "10.0.0.0/20", availability_zone = "us-east-1a" }]
}
```

A tag versions the whole repo: `v0.3.0` applies to every module.

## Module rules

- Modules never declare a `provider` or a `backend`: the caller provides both.
- `versions.tf` sets the minimum Terraform and AWS provider versions.
- Every `variable` has a `type` and a `description`; every `output` has a `description`.
- Nothing hard-coded: region, account, AZs and IDs come from variables or data sources.
- Validations live on the variable, so errors show up at `plan` time instead of halfway through an `apply`.

## Versions

| Tag | Change |
|---|---|
| `v0.3.0` | Comments, descriptions and validation messages translated to English. No resource changes besides descriptions. |
| `v0.2.0` | `cluster-ecs` module. |
| `v0.1.0` | `vpc` module. |
