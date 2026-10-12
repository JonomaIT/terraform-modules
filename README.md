# terraform-modules

Terraform module library for JonomaIT. Modules describe **how** to build things; what actually exists is decided by the [`infrastructure`](https://github.com/JonomaIT/infrastructure) repo.

## Modules

| Module | What it creates |
|---|---|
| [`vpc`](vpc/) | VPC with public subnets (Internet Gateway) and private subnets, with one NAT Gateway per AZ. |
| [`cluster-ecs`](cluster-ecs/) | ECS cluster (Fargate and Fargate Spot), external ALB, internal ALB, private zone `<project>.internal`, Cloud Map namespaces (service discovery and Service Connect) and an internal NLB in front of the internal ALB, used by an API Gateway VPC Link and as a Global Accelerator endpoint. Optional HTTPS with `acm_certs`; allowed sources and ports with `ingress_cidrs` / `ingress_ports` (e.g. only Cloudflare, only HTTPS); external ALB optional with `external_lb_enabled`. |

## Usage

Always pin a SemVer tag, never a branch:

```hcl
module "vpc" {
  source = "git::https://github.com/JonomaIT/terraform-modules.git//vpc?ref=v0.5.0"

  project_name    = "example"
  cidr            = "10.0.0.0/16"
  public_subnets  = [{ name = "public-1a", cidr = "10.0.48.0/24", availability_zone = "us-east-1a" }]
  private_subnets = [{ name = "private-1a", cidr = "10.0.0.0/20", availability_zone = "us-east-1a" }]
}
```

A tag versions the whole repo: `v0.5.0` applies to every module.

## Module rules

- Modules never declare a `provider` or a `backend`: the caller provides both.
- `versions.tf` sets the minimum Terraform and AWS provider versions.
- Every `variable` has a `type` and a `description`; every `output` has a `description`.
- Nothing hard-coded: region, account, AZs and IDs come from variables or data sources.
- Validations live on the variable, so errors show up at `plan` time instead of halfway through an `apply`.

## Versions

| Tag | Change |
|---|---|
| `v0.5.0` | `cluster-ecs`: `ingress_ports` chooses which ports `ingress_cidrs` may use (e.g. `[443]` to refuse plain HTTP from outside the VPC, failing closed). The VPC keeps 80 and 443. Default `[80, 443]` keeps v0.4.0 behavior. |
| `v0.4.0` | `cluster-ecs`: `ingress_cidrs` restricts ports 80/443 of the NLB and internal ALB (VPC CIDR always allowed); `external_lb_enabled` makes the external ALB optional (external outputs become `null` when disabled); internal ALB answers `(internal, http)` / `(internal, https)` to show how a request arrived. Defaults keep v0.3.x behavior, and `moved` blocks avoid recreating anything when upgrading with them. |
| `v0.3.1` | `cluster-ecs`: internal ALB accepts HTTP/HTTPS from any source. The NLB preserves the client IP, so traffic through Global Accelerator was being dropped by the VPC-only rule. The ALB stays internal. |
| `v0.3.0` | `cluster-ecs`: NLB open to Global Accelerator traffic; optional HTTPS (`acm_certs`) on the internal ALB and the NLB; default listener responses are `200 <project> - <region>`; security groups use `name_prefix` + `create_before_destroy` (safe replacement while attached). Everything translated to English. **Upgrading a deployed v0.2.0 replaces the security groups** (new descriptions/names), without downtime thanks to `create_before_destroy`. |
| `v0.2.0` | `cluster-ecs` module. |
| `v0.1.0` | `vpc` module. |
