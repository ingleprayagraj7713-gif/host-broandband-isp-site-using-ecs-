#!/usr/bin/env bash
set -euo pipefail

AWS_REGION="us-east-1"
CLUSTER_NAME="viztel-test-cluster"
SUBNET_IDS="subnet-0fce32001d433c498 subnet-08f0362c972ce1d2b"
ALB_SG="sg-07cae1d0c4f4bb990"

export AWS_DEFAULT_REGION="$AWS_REGION"

# Create ALB
aws elbv2 create-load-balancer \
  --name viztel-test-alb \
  --subnets $SUBNET_IDS \
  --security-groups "$ALB_SG" \
  --scheme internet-facing \
  --type application \
  --region "$AWS_REGION"

# Create target groups and listeners
aws elbv2 create-target-group \
  --name viztel-frontend-tg \
  --protocol HTTP --port 3000 --target-type ip \
  --vpc-id vpc-0750da709442cc3c1 \
  --health-check-path / \
  --region "$AWS_REGION"

aws elbv2 create-target-group \
  --name viztel-backend-tg \
  --protocol HTTP --port 5000 --target-type ip \
  --vpc-id vpc-0750da709442cc3c1\
  --health-check-path /api/health \
  --region "$AWS_REGION"

# ECS cluster
aws ecs create-cluster --cluster-name "$CLUSTER_NAME" --region "$AWS_REGION"

echo "ALB and ECS cluster created. Add listener rules and services in the AWS Console or via additional CLI steps."
