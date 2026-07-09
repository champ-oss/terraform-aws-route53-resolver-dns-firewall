resource "aws_cloudwatch_log_group" "this" {
  count = var.enabled && var.enable_query_logging ? 1 : 0

  name              = "/aws/route53resolver/${var.git}"
  retention_in_days = var.log_retention_days

  tags = local.tags
}

resource "aws_cloudwatch_log_resource_policy" "this" {
  count = var.enabled && var.enable_query_logging ? 1 : 0

  policy_name = "${var.git}-route53resolver"

  policy_document = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Route53ResolverQueryLogging"
        Effect = "Allow"
        Principal = {
          Service = "route53resolver.amazonaws.com"
        }
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.this[0].arn}:*"
      }
    ]
  })
}

resource "aws_route53_resolver_query_log_config" "this" {
  count = var.enabled && var.enable_query_logging ? 1 : 0

  name            = "${var.git}-query-logs"
  destination_arn = aws_cloudwatch_log_group.this[0].arn

  tags = local.tags

  depends_on = [
    aws_cloudwatch_log_resource_policy.this
  ]
}

resource "aws_route53_resolver_query_log_config_association" "this" {
  count = var.enabled && var.enable_query_logging ? 1 : 0

  resolver_query_log_config_id = aws_route53_resolver_query_log_config.this[0].id
  resource_id                  = var.vpc_id
}