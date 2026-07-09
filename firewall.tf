resource "aws_route53_resolver_firewall_domain_list" "allow" {
  count = var.enabled && length(var.allow_domains) > 0 ? 1 : 0

  name    = "${var.git}-allow"
  domains = var.allow_domains
}

resource "aws_route53_resolver_firewall_domain_list" "deny" {
  count = var.enabled && length(var.deny_domains) > 0 ? 1 : 0

  name    = "${var.git}-deny"
  domains = var.deny_domains
}

resource "aws_route53_resolver_firewall_rule" "allow" {
  count = var.enabled && length(var.allow_domains) > 0 ? 1 : 0

  firewall_rule_group_id  = aws_route53_resolver_firewall_rule_group.this[0].id
  firewall_domain_list_id = aws_route53_resolver_firewall_domain_list.allow[0].id

  action   = "ALLOW"
  priority = 100
}

resource "aws_route53_resolver_firewall_rule" "deny" {
  count = var.enabled && length(var.deny_domains) > 0 ? 1 : 0

  firewall_rule_group_id  = aws_route53_resolver_firewall_rule_group.this[0].id
  firewall_domain_list_id = aws_route53_resolver_firewall_domain_list.deny[0].id

  action         = "BLOCK"
  block_response = "NODATA"
  priority       = 200
}

resource "aws_route53_resolver_firewall_rule_group" "this" {
  count = var.enabled && var.enabled_r53_resolver_firewall ? 1 : 0

  name = var.git

  tags = merge(local.tags,var.tags)
}

resource "aws_route53_resolver_firewall_rule_group_association" "this" {
  count = var.enabled && var.enabled_r53_resolver_firewall ? 1 : 0

  firewall_rule_group_id = aws_route53_resolver_firewall_rule_group.this[0].id

  vpc_id   = var.vpc_id
  name     = var.git
  priority = var.association_priority

  mutation_protection = var.mutation_protection

  tags = local.tags
}

