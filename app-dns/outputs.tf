output "names" {
  description = "Public names created for the app"
  value       = [for r in cloudflare_dns_record.app : r.name]
}
