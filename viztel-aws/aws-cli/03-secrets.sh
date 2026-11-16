#!/usr/bin/env bash
set -euo pipefail

AWS_REGION="us-east-1"
SECRET_NAME="viztel-test-secrets"

: "${DB_HOST:?Set DB_HOST before running this script}"
: "${DB_USER:?Set DB_USER before running this script}"
: "${DB_PASSWORD:?Set DB_PASSWORD before running this script}"
: "${JWT_SECRET:?Set JWT_SECRET before running this script}"
: "${RAZORPAY_KEY:?Set RAZORPAY_KEY before running this script}"
: "${RAZORPAY_SECRET:?Set RAZORPAY_SECRET before running this script}"

export AWS_DEFAULT_REGION="$AWS_REGION"

SECRET_STRING="$(jq -n \
  --arg DB_HOST "$DB_HOST" \
  --arg DB_USER "$DB_USER" \
  --arg DB_PASSWORD "$DB_PASSWORD" \
  --arg JWT_SECRET "$JWT_SECRET" \
  --arg RAZORPAY_KEY "$RAZORPAY_KEY" \
  --arg RAZORPAY_SECRET "$RAZORPAY_SECRET" \
  '{DB_HOST: $DB_HOST, DB_USER: $DB_USER, DB_PASSWORD: $DB_PASSWORD, JWT_SECRET: $JWT_SECRET, RAZORPAY_KEY: $RAZORPAY_KEY, RAZORPAY_SECRET: $RAZORPAY_SECRET}')"

aws secretsmanager create-secret \
  --name "$SECRET_NAME" \
  --description "Viztel Fiber TEST environment secrets" \
  --secret-string "$SECRET_STRING" \
  --region "$AWS_REGION"

echo "Secret created: $SECRET_NAME"
