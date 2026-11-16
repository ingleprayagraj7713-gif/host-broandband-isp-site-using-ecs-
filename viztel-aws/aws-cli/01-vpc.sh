#!/usr/bin/env bash
set -euo pipefail

AWS_REGION="us-east-1"
VPC_NAME="viztel-test-vpc"
IGW_NAME="viztel-test-igw"
ROUTE_TABLE_NAME="viztel-test-public-rt"
SUBNET_1="10.0.1.0/24"
SUBNET_2="10.0.2.0/24"

export AWS_DEFAULT_REGION="$AWS_REGION"

VPC_ID=$(aws ec2 create-vpc \
  --cidr-block 10.0.0.0/16 \
  --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=${VPC_NAME}}]" \
  --query 'Vpc.VpcId' --output text)

aws ec2 modify-vpc-attribute --vpc-id "$VPC_ID" --enable-dns-hostnames

SUBNET_1_ID=$(aws ec2 create-subnet \
  --vpc-id "$VPC_ID" \
  --cidr-block 10.0.1.0/24 \
  --availability-zone us-east-1a \
  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=viztel-public-1}]" \
  --query 'Subnet.SubnetId' --output text)

SUBNET_2_ID=$(aws ec2 create-subnet \
  --vpc-id "$VPC_ID" \
  --cidr-block 10.0.2.0/24 \
  --availability-zone us-east-1b \
  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=viztel-public-2}]" \
  --query 'Subnet.SubnetId' --output text)

IGW_ID=$(aws ec2 create-internet-gateway \
  --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=${IGW_NAME}}]" \
  --query 'InternetGateway.InternetGatewayId' --output text)

aws ec2 attach-internet-gateway --vpc-id "$VPC_ID" --internet-gateway-id "$IGW_ID"

RTB_ID=$(aws ec2 create-route-table --vpc-id "$VPC_ID" \
  --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=${ROUTE_TABLE_NAME}}]" \
  --query 'RouteTable.RouteTableId' --output text)

aws ec2 create-route --route-table-id "$RTB_ID" --destination-cidr-block 0.0.0.0/0 --gateway-id "$IGW_ID"
aws ec2 associate-route-table --subnet-id "$SUBNET_1_ID" --route-table-id "$RTB_ID"
aws ec2 associate-route-table --subnet-id "$SUBNET_2_ID" --route-table-id "$RTB_ID"

aws ec2 modify-subnet-attribute --subnet-id "$SUBNET_1_ID" --map-public-ip-on-launch
aws ec2 modify-subnet-attribute --subnet-id "$SUBNET_2_ID" --map-public-ip-on-launch

printf 'VPC_ID=%s\nSUBNET_1_ID=%s\nSUBNET_2_ID=%s\nIGW_ID=%s\nRTB_ID=%s\n' "$VPC_ID" "$SUBNET_1_ID" "$SUBNET_2_ID" "$IGW_ID" "$RTB_ID"
