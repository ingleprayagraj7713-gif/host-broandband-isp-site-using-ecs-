#!/usr/bin/env bash
set -euo pipefail

AWS_REGION="us-east-1"
DB_SUBNET_GROUP="viztel-test-db-subnet-group"
DB_NAME="viztel"
DB_IDENTIFIER="viztel-test-db"
DB_USERNAME="admin"
: "${DB_PASSWORD:?Set DB_PASSWORD before running this script}"
VPC_ID="vpc-0750da709442cc3c1"
SECURITY_GROUP_ID="sg-07cae1d0c4f4bb990"

export AWS_DEFAULT_REGION="$AWS_REGION"

aws rds create-db-subnet-group \
  --db-subnet-group-name "$DB_SUBNET_GROUP" \
  --db-subnet-group-description "Viztel test subnet group" \
  --subnet-ids subnet-0fce32001d433c498 subnet-08f0362c972ce1d2b \
  --region "$AWS_REGION"

aws rds create-db-instance \
  --db-instance-identifier "$DB_IDENTIFIER" \
  --db-name "$DB_NAME" \
  --db-instance-class db.t3.micro \
  --engine mysql \
  --engine-version 8.0.37 \
  --allocated-storage 20 \
  --storage-type gp2 \
  --master-username "$DB_USERNAME" \
  --master-user-password "$DB_PASSWORD" \
  --db-subnet-group-name "$DB_SUBNET_GROUP" \
  --vpc-security-group-ids "$SECURITY_GROUP_ID" \
  --backup-retention-period 7 \
  --region "$AWS_REGION"

echo "DB creation initiated for $DB_IDENTIFIER"
