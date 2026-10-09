# terraform-modules

Biblioteca de módulos Terraform da JonomaIT. Os módulos descrevem **como** construir; quem decide **o quê** existe é o repo [`infrastructure`](https://github.com/JonomaIT/infrastructure).

## Módulos

| Módulo | O que cria |
|---|---|
| [`vpc`](vpc/) | VPC com subnets públicas (Internet Gateway) e privadas, com um NAT Gateway por AZ. |
| [`cluster-ecs`](cluster-ecs/) | Cluster ECS (Fargate e Fargate Spot), ALB externo, ALB interno, zona privada `<projeto>.internal`, namespaces do Cloud Map (service discovery e Service Connect) e VPC Link do API Gateway via NLB. |

## Uso

Sempre por uma tag SemVer, nunca por branch:

```hcl
module "vpc" {
  source = "git::https://github.com/JonomaIT/terraform-modules.git//vpc?ref=v0.2.0"

  project_name    = "exemplo"
  cidr            = "10.0.0.0/16"
  public_subnets  = [{ name = "public-1a", cidr = "10.0.48.0/24", availability_zone = "us-east-1a" }]
  private_subnets = [{ name = "private-1a", cidr = "10.0.0.0/20", availability_zone = "us-east-1a" }]
}
```

A tag versiona o repo inteiro: `v0.2.0` vale para todos os módulos.

## Regras dos módulos

- Módulo não declara `provider` nem `backend`: quem chama passa os dois.
- `versions.tf` com a versão mínima do Terraform e do provider AWS.
- Toda `variable` tem `type` e `description`; todo `output` tem `description`.
- Nada fixo: região, conta, AZ e IDs vêm de variável ou data source.
- Validações na própria variável, para o erro aparecer no `plan` e não no meio do `apply`.

## Versões

| Tag | Mudança |
|---|---|
| `v0.2.0` | Módulo `cluster-ecs`. |
| `v0.1.0` | Módulo `vpc`. |
