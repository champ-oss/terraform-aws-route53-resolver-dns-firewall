#!/usr/bin/env bash

set -euo pipefail

CLUSTER=$(terraform output -raw ecs_cluster_name)
TASK_DEFINITION=$(terraform output -raw ecs_task_definition)
SUBNET=$(terraform output -raw public_subnet_id)
SECURITY_GROUP=$(terraform output -raw dns_test_security_group_id)

TASK_ARN=$(aws ecs run-task \
  --cluster "$CLUSTER" \
  --launch-type FARGATE \
  --task-definition "$TASK_DEFINITION" \
  --network-configuration "awsvpcConfiguration={subnets=[\"$SUBNET\"],securityGroups=[\"$SECURITY_GROUP\"],assignPublicIp=ENABLED}" \
  --query 'tasks[0].taskArn' \
  --output text)

echo "Task started: $TASK_ARN"

echo "Waiting 300 seconds..."
sleep 300

echo "Stopping task..."
aws ecs stop-task \
  --cluster "$CLUSTER" \
  --task "$TASK_ARN"

echo "Waiting for task to stop..."
aws ecs wait tasks-stopped \
  --cluster "$CLUSTER" \
  --tasks "$TASK_ARN"

echo "Task stopped."
echo "You can now run:"
echo "terraform destroy"