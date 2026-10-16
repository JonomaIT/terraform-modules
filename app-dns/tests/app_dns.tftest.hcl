mock_provider "cloudflare" {
  mock_data "cloudflare_zone" {
    defaults = { id = "zone123" }
  }
}

variables {
  zone   = "example.com"
  hosts  = ["hello.example.com"]
  target = "ingress.example.com"
  owner  = "svc-hello"
}

run "proxied_cname_to_the_ingress_with_owner" {
  command = plan

  assert {
    condition = (
      cloudflare_dns_record.app["hello.example.com"].type == "CNAME" &&
      cloudflare_dns_record.app["hello.example.com"].content == "ingress.example.com" &&
      cloudflare_dns_record.app["hello.example.com"].proxied == true &&
      startswith(cloudflare_dns_record.app["hello.example.com"].comment, "owner: svc-hello")
    )
    error_message = "Each host is a proxied CNAME to the ingress, marked with its owner."
  }
}

# The owner check (a name that exists with another owner) reads Cloudflare: mocks cannot fake the
# nested list it returns, so it is tested against the real zone (see README).

run "reserved_name_is_refused" {
  command = plan

  variables {
    hosts = ["ingress.example.com"]
  }

  expect_failures = [var.hosts]
}

run "two_levels_are_refused" {
  command = plan

  variables {
    hosts = ["api.stg.example.com"]
  }

  expect_failures = [var.hosts]
}
