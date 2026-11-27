# Smallest working use of the app-dns module. Copy this folder to start: change the values, keep the
# shape. In a real repo, pin the source to a release tag instead of the relative path:
#   source = "git::https://github.com/JonomaIT/terraform-modules.git//app-dns?ref=app-dns/vX.Y.Z"

provider "cloudflare" {} # token from CLOUDFLARE_API_TOKEN

module "dns" {
  source = "../../"

  zone   = "example.com"
  hosts  = ["orders"]                # orders.example.com
  target = "ingress.stg.example.com" # the environment's entry, owned by the platform
  owner  = "svc-orders"              # written in the record comment; another owner is refused
}
