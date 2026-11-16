#!/usr/bin/env bash
set -euo pipefail

AWS_REGION="${AWS_REGION:-us-east-1}"
CLUSTER_NAME="viztel-test-cluster"
ALB_NAME="viztel-test-alb"
FRONTEND_REPO="viztel-frontend"
BACKEND_REPO="viztel-backend"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"
APP_DIR="${PROJECT_DIR}/viztel-app"
DOCKER_DIR="${PROJECT_DIR}/viztel-aws/docker"
TASK_DIR="${PROJECT_DIR}/viztel-aws/ecs"

export AWS_DEFAULT_REGION="$AWS_REGION"

for command in aws docker jq; do
  command -v "$command" >/dev/null 2>&1 || {
    echo "Required command not found: $command" >&2
    exit 1
  }
done

AWS_ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
EXECUTION_ROLE_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:role/ecsTaskExecutionRole"
aws iam get-role --role-name ecsTaskExecutionRole >/dev/null

ALB_ARN="$(aws elbv2 describe-load-balancers \
  --names "$ALB_NAME" \
  --region "$AWS_REGION" \
  --query 'LoadBalancers[0].LoadBalancerArn' \
  --output text)"
if [[ -z "$ALB_ARN" || "$ALB_ARN" == "None" ]]; then
  echo "Required load balancer not found: $ALB_NAME" >&2
  exit 1
fi

VPC_ID="$(aws elbv2 describe-load-balancers \
  --load-balancer-arns "$ALB_ARN" \
  --region "$AWS_REGION" \
  --query 'LoadBalancers[0].VpcId' \
  --output text)"
read -r -a SUBNET_IDS <<< "$(aws elbv2 describe-load-balancers \
  --load-balancer-arns "$ALB_ARN" \
  --region "$AWS_REGION" \
  --query 'LoadBalancers[0].AvailabilityZones[].SubnetId' \
  --output text)"
if [[ "${#SUBNET_IDS[@]}" -lt 2 ]]; then
  echo "$ALB_NAME must be attached to at least two subnets." >&2
  exit 1
fi

ensure_ecr_repository() {
  local repository="$1"
  if ! aws ecr describe-repositories \
      --repository-names "$repository" \
      --region "$AWS_REGION" >/dev/null 2>&1; then
    aws ecr create-repository \
      --repository-name "$repository" \
      --image-scanning-configuration scanOnPush=true \
      --region "$AWS_REGION" >/dev/null
  fi
}

ensure_security_group() {
  local name="$1"
  local description="$2"
  local port="$3"
  local source_group="$4"
  local group_id

  group_id="$(aws ec2 describe-security-groups \
    --filters "Name=vpc-id,Values=${VPC_ID}" "Name=group-name,Values=${name}" \
    --region "$AWS_REGION" \
    --query 'SecurityGroups[0].GroupId' \
    --output text)"
  if [[ -z "$group_id" || "$group_id" == "None" ]]; then
    group_id="$(aws ec2 create-security-group \
      --group-name "$name" \
      --description "$description" \
      --vpc-id "$VPC_ID" \
      --region "$AWS_REGION" \
      --query GroupId \
      --output text)"
  fi

  if [[ -n "$source_group" ]]; then
    if ! aws ec2 describe-security-groups \
        --group-ids "$group_id" \
        --region "$AWS_REGION" \
        --output json |
        jq -e --argjson port "$port" --arg source_group "$source_group" \
          'any(.SecurityGroups[0].IpPermissions[]?;
            .FromPort == $port and
            any(.UserIdGroupPairs[]?; .GroupId == $source_group))' >/dev/null; then
      aws ec2 authorize-security-group-ingress \
        --group-id "$group_id" \
        --protocol tcp \
        --port "$port" \
        --source-group "$source_group" \
        --region "$AWS_REGION" >/dev/null
    fi
  else
    if ! aws ec2 describe-security-groups \
        --group-ids "$group_id" \
        --region "$AWS_REGION" \
        --output json |
        jq -e --argjson port "$port" \
          'any(.SecurityGroups[0].IpPermissions[]?;
            .FromPort == $port and
            any(.IpRanges[]?; .CidrIp == "0.0.0.0/0"))' >/dev/null; then
      aws ec2 authorize-security-group-ingress \
        --group-id "$group_id" \
        --protocol tcp \
        --port "$port" \
        --cidr 0.0.0.0/0 \
        --region "$AWS_REGION" >/dev/null
    fi
  fi
  printf '%s' "$group_id"
}

ensure_target_group() {
  local name="$1"
  local port="$2"
  local health_path="$3"
  local target_group_arn

  target_group_arn="$(aws elbv2 describe-target-groups \
    --names "$name" \
    --region "$AWS_REGION" \
    --query 'TargetGroups[0].TargetGroupArn' \
    --output text 2>/dev/null || true)"
  if [[ -z "$target_group_arn" || "$target_group_arn" == "None" ]]; then
    target_group_arn="$(aws elbv2 create-target-group \
      --name "$name" \
      --protocol HTTP \
      --port "$port" \
      --target-type ip \
      --vpc-id "$VPC_ID" \
      --health-check-path "$health_path" \
      --health-check-protocol HTTP \
      --matcher HttpCode=200 \
      --region "$AWS_REGION" \
      --query 'TargetGroups[0].TargetGroupArn' \
      --output text)"
  fi
  printf '%s' "$target_group_arn"
}

ensure_ecr_repository "$FRONTEND_REPO"
ensure_ecr_repository "$BACKEND_REPO"
aws ecr get-login-password --region "$AWS_REGION" | \
  docker login --username AWS --password-stdin \
    "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

FRONTEND_IMAGE="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${FRONTEND_REPO}:latest"
BACKEND_IMAGE="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${BACKEND_REPO}:latest"
FRONTEND_LOCAL_IMAGE="viztel-frontend:latest"
BACKEND_LOCAL_IMAGE="viztel-backend:latest"

docker buildx build \
  --platform linux/amd64 \
  --load \
  --file "${DOCKER_DIR}/Dockerfile.frontend" \
  --tag "$FRONTEND_LOCAL_IMAGE" \
  "${APP_DIR}/frontend"
docker tag "$FRONTEND_LOCAL_IMAGE" "$FRONTEND_IMAGE"
docker push "$FRONTEND_IMAGE"
docker buildx build \
  --platform linux/amd64 \
  --load \
  --file "${DOCKER_DIR}/Dockerfile.backend" \
  --tag "$BACKEND_LOCAL_IMAGE" \
  "${APP_DIR}/backend"
docker tag "$BACKEND_LOCAL_IMAGE" "$BACKEND_IMAGE"
docker push "$BACKEND_IMAGE"

ALB_SG_ID="$(ensure_security_group viztel-alb-sg 'Viztel public ALB HTTP ingress' 80 '')"
FRONTEND_SG_ID="$(ensure_security_group viztel-frontend-sg 'Viztel frontend from ALB' 3000 "$ALB_SG_ID")"
BACKEND_SG_ID="$(ensure_security_group viztel-backend-sg 'Viztel backend from ALB' 5000 "$ALB_SG_ID")"
aws elbv2 set-security-groups \
  --load-balancer-arn "$ALB_ARN" \
  --security-groups "$ALB_SG_ID" \
  --region "$AWS_REGION" >/dev/null

FRONTEND_TG_ARN="$(ensure_target_group viztel-frontend-tg 3000 /)"
BACKEND_TG_ARN="$(ensure_target_group viztel-backend-tg 5000 /api/health)"

if [[ "$(aws ecs describe-clusters \
    --clusters "$CLUSTER_NAME" \
    --region "$AWS_REGION" \
    --query 'clusters[0].status' \
    --output text)" != "ACTIVE" ]]; then
  aws ecs create-cluster --cluster-name "$CLUSTER_NAME" --region "$AWS_REGION" >/dev/null
fi

for log_group in /ecs/viztel-frontend /ecs/viztel-backend; do
  if ! aws logs describe-log-groups \
      --log-group-name-prefix "$log_group" \
      --region "$AWS_REGION" \
      --query "logGroups[?logGroupName=='${log_group}'] | length(@)" \
      --output text | grep -q '^1$'; then
    aws logs create-log-group --log-group-name "$log_group" --region "$AWS_REGION"
  fi
done

LISTENER_ARN="$(aws elbv2 describe-listeners \
  --load-balancer-arn "$ALB_ARN" \
  --region "$AWS_REGION" \
  --query 'Listeners[?Port==`80`].ListenerArn | [0]' \
  --output text)"
if [[ -z "$LISTENER_ARN" || "$LISTENER_ARN" == "None" ]]; then
  LISTENER_ARN="$(aws elbv2 create-listener \
    --load-balancer-arn "$ALB_ARN" \
    --protocol HTTP \
    --port 80 \
    --default-actions "Type=forward,TargetGroupArn=${FRONTEND_TG_ARN}" \
    --region "$AWS_REGION" \
    --query 'Listeners[0].ListenerArn' \
    --output text)"
else
  aws elbv2 modify-listener \
    --listener-arn "$LISTENER_ARN" \
    --default-actions "Type=forward,TargetGroupArn=${FRONTEND_TG_ARN}" \
    --region "$AWS_REGION" >/dev/null
fi

API_RULE_ARN="$(aws elbv2 describe-rules \
  --listener-arn "$LISTENER_ARN" \
  --region "$AWS_REGION" \
  --query "Rules[?Conditions[?Field=='path-pattern' && Values[?contains(@, '/api/*')]]].RuleArn | [0]" \
  --output text)"
if [[ -z "$API_RULE_ARN" || "$API_RULE_ARN" == "None" ]]; then
  aws elbv2 create-rule \
    --listener-arn "$LISTENER_ARN" \
    --priority 10 \
    --conditions 'Field=path-pattern,Values=/api/*' \
    --actions "Type=forward,TargetGroupArn=${BACKEND_TG_ARN}" \
    --region "$AWS_REGION" >/dev/null
else
  aws elbv2 modify-rule \
    --rule-arn "$API_RULE_ARN" \
    --conditions 'Field=path-pattern,Values=/api/*' \
    --actions "Type=forward,TargetGroupArn=${BACKEND_TG_ARN}" \
    --region "$AWS_REGION" >/dev/null
fi

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

NETWORK_CONFIG="awsvpcConfiguration={subnets=[$(IFS=,; echo "${SUBNET_IDS[*]}")],securityGroups=[${FRONTEND_SG_ID}],assignPublicIp=ENABLED}"
BACKEND_NETWORK_CONFIG="awsvpcConfiguration={subnets=[$(IFS=,; echo "${SUBNET_IDS[*]}")],securityGroups=[${BACKEND_SG_ID}],assignPublicIp=ENABLED}"
if [[ "$(aws ecs describe-services \
    --cluster "$CLUSTER_NAME" \
    --services viztel-frontend \
    --region "$AWS_REGION" \
    --query 'services[0].status' \
    --output text 2>/dev/null || true)" == "ACTIVE" ]]; then
  aws ecs update-service \
    --cluster "$CLUSTER_NAME" \
    --service viztel-frontend \
    --task-definition "$FRONTEND_TASK_ARN" \
    --desired-count 1 \
    --network-configuration "$NETWORK_CONFIG" \
    --load-balancers "targetGroupArn=${FRONTEND_TG_ARN},containerName=viztel-frontend,containerPort=3000" \
    --force-new-deployment \
    --region "$AWS_REGION" >/dev/null
else
  aws ecs create-service \
    --cluster "$CLUSTER_NAME" \
    --service-name viztel-frontend \
    --task-definition "$FRONTEND_TASK_ARN" \
    --desired-count 1 \
    --launch-type FARGATE \
    --network-configuration "$NETWORK_CONFIG" \
    --load-balancers "targetGroupArn=${FRONTEND_TG_ARN},containerName=viztel-frontend,containerPort=3000" \
    --region "$AWS_REGION" >/dev/null
fi

if [[ "$(aws ecs describe-services \
    --cluster "$CLUSTER_NAME" \
    --services viztel-backend \
    --region "$AWS_REGION" \
    --query 'services[0].status' \
    --output text 2>/dev/null || true)" == "ACTIVE" ]]; then
  aws ecs update-service \
    --cluster "$CLUSTER_NAME" \
    --service viztel-backend \
    --task-definition "$BACKEND_TASK_ARN" \
    --desired-count 1 \
    --network-configuration "$BACKEND_NETWORK_CONFIG" \
    --load-balancers "targetGroupArn=${BACKEND_TG_ARN},containerName=viztel-backend,containerPort=5000" \
    --force-new-deployment \
    --region "$AWS_REGION" >/dev/null
else
  aws ecs create-service \
    --cluster "$CLUSTER_NAME" \
    --service-name viztel-backend \
    --task-definition "$BACKEND_TASK_ARN" \
    --desired-count 1 \
    --launch-type FARGATE \
    --network-configuration "$BACKEND_NETWORK_CONFIG" \
    --load-balancers "targetGroupArn=${BACKEND_TG_ARN},containerName=viztel-backend,containerPort=5000" \
    --region "$AWS_REGION" >/dev/null
fi

echo "Waiting for ECS services to stabilize..."
aws ecs wait services-stable \
  --cluster "$CLUSTER_NAME" \
  --services viztel-frontend viztel-backend \
  --region "$AWS_REGION"
aws elbv2 wait target-in-service --target-group-arn "$FRONTEND_TG_ARN" --region "$AWS_REGION"
aws elbv2 wait target-in-service --target-group-arn "$BACKEND_TG_ARN" --region "$AWS_REGION"

ALB_DNS="$(aws elbv2 describe-load-balancers \
  --load-balancer-arns "$ALB_ARN" \
  --region "$AWS_REGION" \
  --query 'LoadBalancers[0].DNSName' \
  --output text)"
echo "Deployment is healthy: http://${ALB_DNS}"
echo "API health: http://${ALB_DNS}/api/health"
echo "The API is running without a database; persistent database features are not configured."
