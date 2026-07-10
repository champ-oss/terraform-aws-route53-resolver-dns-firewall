provider "aws" {
  region = "us-east-2"
}

locals {
  git = "terraform-aws-resolver-dns-firewall"
  tags = {
    git     = local.git
    cost    = "shared"
    creator = "terraform"
  }
}

data "aws_vpcs" "this" {
  tags = {
    purpose = "vega"
  }
}

data "aws_subnets" "public" {
  tags = {
    purpose = "vega"
    Type    = "Public"
  }

  filter {
    name   = "vpc-id"
    values = [data.aws_vpcs.this.ids[0]]
  }
}

resource "aws_iam_role" "ecs_execution" {
  name = "dns-query-test-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_cluster" "this" {
  name = "dns-query-test"

  tags = local.tags
}

resource "aws_security_group" "dns_test" {
  name        = "dns-query-test"
  description = "DNS query logging test"
  vpc_id      = data.aws_vpcs.this.ids[0]

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

resource "aws_ecs_task_definition" "dns_test" {
  family                   = "dns-query-test"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  cpu    = 256
  memory = 512

  execution_role_arn = aws_iam_role.ecs_execution.arn

  container_definitions = jsonencode([
    {
      name      = "dns-test"
      image     = "public.ecr.aws/amazonlinux/amazonlinux:2023"
      essential = true

      command = [
        "sh",
        "-c",
        "dnf install -y bind-utils >/dev/null 2>&1 && dig amazonaws.com >/dev/null && dig github.com >/dev/null && dig api.github.com >/dev/null && dig example.com >/dev/null && tail -f /dev/null"
      ]
    }
  ])

  tags = local.tags
}

module "this" {
  source                        = "../../"
  vpc_id                        = data.aws_vpcs.this.ids[0]
  enable_query_logging          = true
  deny_domains                  = ["*.example.com."]
  enabled_r53_resolver_firewall = true
  association_priority          = 500
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.this.name
}

output "ecs_task_definition" {
  value = aws_ecs_task_definition.dns_test.family
}

output "public_subnet_id" {
  value = data.aws_subnets.public.ids[0]
}

output "dns_test_security_group_id" {
  value = aws_security_group.dns_test.id
}