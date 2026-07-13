# terraform-aws-route53-resolver-dns-firewall

Terraform module to provision Amazon Route 53 Resolver DNS Firewall and optional Route 53 Resolver Query Logging.

## Features

* Route 53 Resolver DNS Firewall
* Allow and deny domain lists
* Firewall rule group and VPC association
* Optional Route 53 Resolver Query Logging
* CloudWatch Log Group for DNS query logs
* Configurable tagging

---

# Requirements

| Name         | Version |
| ------------ | ------- |
| Terraform    | >= 1.2  |
| AWS Provider | >= 6.0  |

---

# Usage

## Enable Query Logging Only

```hcl
module "route53_resolver_dns_firewall" {
  source = "..."

  enabled = true

  git    = "shared"
  vpc_id = module.vpc.vpc_id

  enable_query_logging = true

  tags = {
    Environment = "dev"
  }
}
```

---

## Block Domains

```hcl
module "route53_resolver_dns_firewall" {
  source = "..."

  enabled = true

  git    = "shared"
  vpc_id = module.vpc.vpc_id

  enabled_r53_resolver_firewall = true

  deny_domains = [
    "example.com.",
    "*.example.com."
  ]
}
```

---

## Allow Domains

```hcl
module "route53_resolver_dns_firewall" {
  source = "..."

  enabled = true

  git    = "shared"
  vpc_id = module.vpc.vpc_id

  enabled_r53_resolver_firewall = true

  allow_domains = [
    "github.com.",
    "*.amazonaws.com."
  ]
}
```

---

# Inputs

| Name                          | Description                                                        | Type         | Default      | Required |
| ----------------------------- | ------------------------------------------------------------------ | ------------ | ------------ | :------: |
| enabled                       | Enable the module                                                  | bool         | `true`       |    No    |
| git                           | Resource name prefix                                               | string       | n/a          |    Yes   |
| vpc_id                        | VPC ID to associate with                                           | string       | n/a          |    Yes   |
| enabled_r53_resolver_firewall | Enable Route 53 Resolver DNS Firewall                              | bool         | `false`      |    No    |
| enable_query_logging          | Enable Route 53 Resolver Query Logging                             | bool         | `false`      |    No    |
| allow_domains                 | List of allowed FQDNs                                              | list(string) | `[]`         |    No    |
| deny_domains                  | List of blocked FQDNs                                              | list(string) | `[]`         |    No    |
| association_priority          | Firewall rule group association priority                           | number       | `500`        |    No    |
| mutation_protection           | Firewall association mutation protection (`ENABLED` or `DISABLED`) | string       | `"DISABLED"` |    No    |
| log_retention_days            | CloudWatch Logs retention period                                   | number       | `30`         |    No    |
| tags                          | Tags applied to supported resources                                | map(string)  | `{}`         |    No    |

---

# Outputs

| Name                     | Description                                  |
| ------------------------ | -------------------------------------------- |
| firewall_rule_group_id   | Firewall rule group ID                       |
| association_id           | Firewall rule group association ID           |
| allow_domain_list_id     | Allow domain list ID                         |
| deny_domain_list_id      | Deny domain list ID                          |
| query_log_config_id      | Route 53 Resolver query log configuration ID |
| query_log_association_id | Route 53 Resolver query log association ID   |

---

# Testing

The `examples/complete` example deploys a temporary ECS Fargate task that performs DNS lookups to generate Route 53 Resolver query logs.

```bash
terraform init
terraform apply

./test.sh

terraform destroy
```

---

# Example Query Log

When Route 53 Resolver Query Logging and DNS Firewall are both enabled, blocked queries include the firewall action and the firewall resources that matched.

```json
{
  "version": "1.100000",
  "account_id": "123456789012",
  "region": "us-east-2",
  "vpc_id": "vpc-xxxxxxxxxxxxxxxxx",
  "query_timestamp": "2026-07-10T19:09:28Z",
  "query_name": "www.example.com.",
  "query_type": "A",
  "query_class": "IN",
  "rcode": "NOERROR",
  "answers": [],
  "srcaddr": "10.0.16.116",
  "srcport": "54089",
  "transport": "UDP",
  "srcids": {
    "instance": "i-xxxxxxxxxxxxxxxxx"
  },
  "firewall_rule_action": "BLOCK",
  "firewall_rule_group_id": "rslvr-frg-xxxxxxxxxxxxxxxx",
  "firewall_domain_list_id": "rslvr-fdl-xxxxxxxxxxxxxxxx"
}
```

## Blocked Queries

Blocked queries include the following fields:

* `firewall_rule_action`
* `firewall_rule_group_id`
* `firewall_domain_list_id`

When `block_response = "NODATA"` is configured, the `answers` array is empty.

## Allowed Queries

Allowed queries appear as standard Route 53 Resolver query log entries containing the resolved DNS records.

Unlike blocked queries, they typically **do not** include:

* `firewall_rule_action`
* `firewall_rule_group_id`
* `firewall_domain_list_id`

Instead, the `answers` array contains the resolved DNS records returned by Route 53 Resolver.

Because of this, Route 53 Resolver query logs alone cannot distinguish between:

* A query that matched an explicit **ALLOW** rule.
* A query that was simply **not blocked**.

Only **BLOCK** actions are explicitly identified in the query logs.

---

# Notes

* Route 53 Resolver Query Logging is associated with a **VPC**. All DNS queries made through the Amazon Route 53 Resolver in that VPC are logged.
* Route 53 Resolver DNS Firewall and Route 53 Resolver Query Logging are independent features and can be enabled separately.
* Specify fully qualified domain names (FQDNs) in `allow_domains` and `deny_domains`, for example:

  * `example.com.`
  * `*.example.com.`
* `*.example.com.` matches only subdomains. To match both the apex domain and all subdomains, specify both:

  * `example.com.`
  * `*.example.com.`
* `association_priority` is only relevant when multiple Route 53 Resolver DNS Firewall rule groups are associated with the same VPC.
* DNS query logging captures queries from all workloads using the Amazon Route 53 Resolver within the associated VPC. Use CloudWatch Logs Insights to filter queries by source IP, domain name, or other log fields.

