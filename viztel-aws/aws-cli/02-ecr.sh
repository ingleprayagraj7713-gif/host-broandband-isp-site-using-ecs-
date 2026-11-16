#!/usr/bin/env bash
set -euo pipefail

AWS_REGION="us-east-1"
REPOS=(viztel-frontend viztel-backend)

export AWS_DEFAULT_REGION="$AWS_REGION"

for repo in "${REPOS[@]}"; do
  aws ecr create-repository \
    --repository-name "$repo" \
    --image-scanning-configuration scanOnPush=true \
    --region "$AWS_REGION" >/dev/null
  echo "Repository created: $repo"
done

aws ecr get-login-password --region "$AWS_REGION" | \
  docker login --username AWS --password-stdin "$(aws sts get-caller-identity --query Account --output text).dkr.ecr.${AWS_REGION}.amazonaws.com"
