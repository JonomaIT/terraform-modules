# lambda-function

**Kind:** pattern. A site's API (`deploy/api.hcl`): a Lambda function on Graviton behind the site's CloudFront at `<host>/api/*`, its function URL only answering CloudFront (AWS_IAM), logs to its own group, the app's data-access policy attached and `parameter_paths` to read its secrets at run time.

The design notes are in the comments at the top of the `.tf` files.

<!-- BEGIN_TF_DOCS -->
## Usage

```hcl
# Smallest working use of the lambda-function module. Copy this folder to start: change the values, keep the
# shape. In a real repo, pin the source to a release tag instead of the relative path:
#   source = "git::https://github.com/JonomaIT/terraform-modules.git//lambda-function?ref=lambda-function/vX.Y.Z"

provider "aws" {
  region = "us-east-1"
}

module "api" {
  source = "../../"

  prefix      = "acme"
  environment = "staging"
  name        = "web-shop"
  source_dir  = "${path.module}/api" # api/index.mjs exports handler
  handler     = "index.handler"
}
```

More in [`examples/`](examples/). Every release of this module is a tag `<module>/vX.Y.Z`, listed in [`CHANGELOG.md`](CHANGELOG.md).

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.10 |
| archive | ~> 2.7 |
| aws | >= 6.0 |

## Providers

| Name | Version |
|------|---------|
| archive | ~> 2.7 |
| aws | >= 6.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Account the function runs in (staging, production, shared-services) | `string` | n/a | yes |
| environment_variables | Plain environment variables (never secrets) | `map(string)` | `{}` | no |
| handler | <file>.<function>, e.g. progress.handler for progress.mjs exporting handler | `string` | n/a | yes |
| log_retention_days | Days the logs are kept | `number` | `30` | no |
| memory | Memory in MB (CPU grows with it) | `number` | `128` | no |
| name | App name = repo name (e.g. web-english) | `string` | n/a | yes |
| parameter_paths | SSM parameter paths the function may read, decrypting SecureStrings with the account's aws/ssm key (e.g. /jonomait/production/web-english/secrets): the app's secrets, set outside Terraform | `list(string)` | `[]` | no |
| policy_arns | Managed policies for the function's role: the app's data-access policy (ADR-011) | `list(string)` | `[]` | no |
| prefix | Platform prefix (e.g. jonomait): the function is <prefix>-<env>-<name>-api | `string` | n/a | yes |
| runtime | Lambda runtime | `string` | `"nodejs22.x"` | no |
| source_dir | Folder with the function's code, zipped as it is (no build step here) | `string` | n/a | yes |
| timeout | Seconds before a call is cut (CloudFront waits 30 s at most) | `number` | `10` | no |

## Outputs

| Name | Description |
|------|-------------|
| function_arn | Lambda function ARN |
| function_name | Lambda function |
| role_name | The function's role |
| url_domain | Host of the function URL: the origin of the API in CloudFront |
<!-- END_TF_DOCS -->
