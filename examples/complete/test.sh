#!/usr/bin/env bash

set -euo pipefail

CLUSTER=$(terraform output -raw ecs_cluster_name)
TASK_DEFINITION=$(terraform output -raw ecs_task_definition)
SUBNET=$(terraform output -raw public_subnet_id)
SECURITY_GROUP=$(terraform output -raw dns_test_security_group_id)

echo "Starting DNS query test task..."

TASK_ARN=$(aws ecs run-task \
  --cluster "$CLUSTER" \
  --launch-type FARGATE \
  --task-definition "$TASK_DEFINITION" \
  --network-configuration "awsvpcConfiguration={subnets=[\"$SUBNET\"],securityGroups=[\"$SECURITY_GROUP\"],assignPublicIp=ENABLED}" \
  --query 'tasks[0].taskArn' \
  --output text)