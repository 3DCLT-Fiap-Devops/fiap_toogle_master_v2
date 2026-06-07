#!/bin/bash

# Script to create a dedicated VPC and Networking for ToogleMaster
# This creates: VPC, Subnet, Internet Gateway, Route Table, and Security Group.

echo "Creating dedicated VPC for ToogleMaster..."

# Get Region
REGION=$(aws configure get region)
REGION=${REGION:-us-east-1}

# 1. Create VPC
VPC_ID=$(aws ec2 create-vpc \
    --cidr-block 10.0.0.0/16 \
    --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=toogle-vpc}]' \
    --query 'Vpc.VpcId' \
    --output text)

aws ec2 modify-vpc-attribute --vpc-id "$VPC_ID" --enable-dns-support "{\"Value\":true}"
aws ec2 modify-vpc-attribute --vpc-id "$VPC_ID" --enable-dns-hostnames "{\"Value\":true}"
echo "VPC Created: $VPC_ID"

# 2. Create Internet Gateway and attach to VPC
IGW_ID=$(aws ec2 create-internet-gateway \
    --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=toogle-igw}]' \
    --query 'InternetGateway.InternetGatewayId' \
    --output text)

aws ec2 attach-internet-gateway --vpc-id "$VPC_ID" --internet-gateway-id "$IGW_ID"
echo "Internet Gateway Created and Attached: $IGW_ID"

# 3. Create Public Subnet (Zone A)
SUBNET_ID=$(aws ec2 create-subnet \
    --vpc-id "$VPC_ID" \
    --cidr-block 10.0.1.0/24 \
    --availability-zone "${REGION}a" \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=toogle-subnet-a}]' \
    --query 'Subnet.SubnetId' \
    --output text)

aws ec2 modify-subnet-attribute --subnet-id "$SUBNET_ID" --map-public-ip-on-launch
echo "Public Subnet Created: $SUBNET_ID"

# 4. Create another Subnet (Zone B) - Required for RDS Subnet Groups
SUBNET_B_ID=$(aws ec2 create-subnet \
    --vpc-id "$VPC_ID" \
    --cidr-block 10.0.2.0/24 \
    --availability-zone "${REGION}b" \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=toogle-subnet-b}]' \
    --query 'Subnet.SubnetId' \
    --output text)

echo "Secondary Subnet Created (for RDS/Redis): $SUBNET_B_ID"

# 5. Create Route Table and add route to Internet
RT_ID=$(aws ec2 create-route-table \
    --vpc-id "$VPC_ID" \
    --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=toogle-rt}]' \
    --query 'RouteTable.RouteTableId' \
    --output text)

aws ec2 create-route --route-table-id "$RT_ID" --destination-cidr-block 0.0.0.0/0 --gateway-id "$IGW_ID"
aws ec2 associate-route-table --subnet-id "$SUBNET_ID" --route-table-id "$RT_ID"
aws ec2 associate-route-table --subnet-id "$SUBNET_B_ID" --route-table-id "$RT_ID"
echo "Route Table Configured for Internet Access."

# 6. Create Security Group
SG_NAME="toogle-master-sg"
SG_ID=$(aws ec2 create-security-group \
    --group-name "$SG_NAME" \
    --description "Security group for ToogleMaster (Public Access)" \
    --vpc-id "$VPC_ID" \
    --query 'GroupId' \
    --output text)

echo "Adding ingress rules to Security Group (0.0.0.0/0)..."
aws ec2 authorize-security-group-ingress --group-id "$SG_ID" --protocol tcp --port 5432 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id "$SG_ID" --protocol tcp --port 6379 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id "$SG_ID" --protocol tcp --port 8001-8005 --cidr 0.0.0.0/0

# 7. Create RDS Subnet Group (Required for RDS in non-default VPC)
aws rds create-db-subnet-group \
    --db-subnet-group-name "toogle-db-subnet-group" \
    --db-subnet-group-description "Subnet group for ToogleMaster RDS" \
    --subnet-ids "$SUBNET_ID" "$SUBNET_B_ID"

# 8. Create ElastiCache Subnet Group (Required for Redis in non-default VPC)
aws elasticache create-cache-subnet-group \
    --cache-subnet-group-name "toogle-cache-subnet-group" \
    --cache-subnet-group-description "Subnet group for ToogleMaster Redis" \
    --subnet-ids "$SUBNET_ID" "$SUBNET_B_ID"

echo "Networking setup complete."
echo "VPC: $VPC_ID"
echo "Security Group: $SG_ID"
echo "Subnets: $SUBNET_ID, $SUBNET_B_ID"
