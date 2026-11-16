#!/usr/bin/env bash
set -euo pipefail

AWS_REGION="${AWS_REGION:-us-east-1}"
IMAGE_TAG="${IMAGE_TAG:?Set IMAGE_TAG to the commit SHA being deployed}"
CLUSTER_NAME="viztel-test-cluster"
FRONTEND_REPO="viztel-frontend"
BACKEND_REPO="viztel-backend"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"
APP_DIR="${PROJECT_DIR}/viztel-app"
DOCKER_DIR="${PROJECT_DIR}/viztel-aws/docker"
TASK_DIR="${PROJECT_DIR}/viztel-aws/ecs"

export AWS_DEFAULT_REGION="$AWS_REGION"

if [[ ! "$IMAGE_TAG" =~ ^[A-Za-z0-9_][A-Za-z0-9_.-]{0,127}$ ]]; then
  echo "IMAGE_TAG must be a valid Docker image tag." >&2
  exit 1
fi

for command in aws docker jq; do
  command -v "$command" >/dev/null 2>&1 || {
    echo "Required command not found: $command" >&2
    exit 1
  }
done

AWS_ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
EXECUTION_ROLE_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:role/ecsTaskExecutionRole"
aws ecr describe-repositories \
  --repository-names "$FRONTEND_REPO" "$BACKEND_REPO" \
  --region "$AWS_REGION" >/dev/null
aws ecs describe-clusters \
  --clusters "$CLUSTER_NAME" \
  --region "$AWS_REGION" \
  --query 'clusters[?status==`ACTIVE`] | length(@)' \
  --output text | grep -q '^1$' || {
  echo "Required ECS cluster is not active: $CLUSTER_NAME" >&2
  exit 1
}

for service in viztel-frontend viztel-backend; do
  service_status="$(aws ecs describe-services \
    --cluster "$CLUSTER_NAME" \
    --services "$service" \
    --region "$AWS_REGION" \
    --query 'services[0].status' \
    --output text)"
  if [[ "$service_status" != "ACTIVE" ]]; then
    echo "Required ECS service is not active: $service" >&2
    exit 1
  fi
done

aws ecr get-login-password --region "$AWS_REGION" | \
  docker login --username AWS --password-stdin \
    "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

FRONTEND_IMAGE="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${FRONTEND_REPO}:${IMAGE_TAG}"
BACKEND_IMAGE="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${BACKEND_REPO}:${IMAGE_TAG}"

docker buildx build \
  --platform linux/amd64 \
  --push \
  --file "${DOCKER_DIR}/Dockerfile.frontend" \
  --tag "$FRONTEND_IMAGE" \
  "${APP_DIR}/frontend"
docker buildx build \
  --platform linux/amd64 \
  --push \
  --file "${DOCKER_DIR}/Dockerfile.backend" \
  --tag "$BACKEND_IMAGE" \
  "${APP_DIR}/backend"

TMP_FRONTEND_TASK="$(mktemp)"
TMP_BACKEND_TASK="$(mktemp)"
trap 'rm -f "$TMP_FRONTEND_TASK" "$TMP_BACKEND_TASK"' EXIT

jq --arg image "$FRONTEND_IMAGE" --arg role "$EXECUTION_ROLE_ARN" \
  '.executionRoleArn = $role
   | del(.taskRoleArn)
   | .containerDefinitions[0].image = $image' \
  "${TASK_DIR}/frontend-task-definition.json" > "$TMP_FRONTEND_TASK"
jq --arg image "$BACKEND_IMAGE" --arg role "$EXECUTION_ROLE_ARN" \
  '.executionRoleArn = $role
   | del(.taskRoleArn)
   | .containerDefinitions[0].image = $image
   | .containerDefinitions[0].environment |= map(select(.name != "DB_HOST"))
   | del(.containerDefinitions[0].secrets)' \
  "${TASK_DIR}/backend-task-definition.json" > "$TMP_BACKEND_TASK"

FRONTEND_TASK_ARN="$(aws ecs register-task-definition \
  --cli-input-json "file://${TMP_FRONTEND_TASK}" \
  --region "$AWS_REGION" \
  --query 'taskDefinition.taskDefinitionArn' \
  --output text)"
BACKEND_TASK_ARN="$(aws ecs register-task-definition \
  --cli-input-json "file://${TMP_BACKEND_TASK}" \
  --region "$AWS_REGION" \
  --query 'taskDefinition.taskDefinitionArn' \
  --output text)"

aws ecs update-service \
  --cluster "$CLUSTER_NAME" \
  --service viztel-frontend \
  --task-definition "$FRONTEND_TASK_ARN" \
  --force-new-deployment \
  --region "$AWS_REGION" >/dev/null
aws ecs update-service \
  --cluster "$CLUSTER_NAME" \
  --service viztel-backend \
  --task-definition "$BACKEND_TASK_ARN" \
  --force-new-deployment \
  --region "$AWS_REGION" >/dev/null

echo "Waiting for ECS services and load balancer targets to stabilize..."
aws ecs wait services-stable \
  --cluster "$CLUSTER_NAME" \
  --services viztel-frontend viztel-backend \
  --region "$AWS_REGION"

for service in viztel-frontend viztel-backend; do
  target_group_arn="$(aws ecs describe-services \
    --cluster "$CLUSTER_NAME" \
    --services "$service" \
    --region "$AWS_REGION" \
    --query 'services[0].loadBalancers[0].targetGroupArn' \
    --output text)"
  if [[ -z "$target_group_arn" || "$target_group_arn" == "None" ]]; then
    echo "No load balancer target group is configured for ECS service: $service" >&2
    exit 1
  fi
  aws elbv2 wait target-in-service \
    --target-group-arn "$target_group_arn" \
    --region "$AWS_REGION"
done

echo "Deployment is healthy: image tag ${IMAGE_TAG}"
