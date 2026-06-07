#!/bin/bash

# RDS Postgres Instances
# 2x 20GB t3.medium
PASSWORD="SenhaTeste123"

echo "Fetching SG_ID for toogle-master-sg..."
# Fetch SG_ID dynamically by name - filtering by VPC if possible
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=toogle-vpc" --query 'Vpcs[0].VpcId' --output text 2>/dev/null)

if [ ! -z "$VPC_ID" ] && [ "$VPC_ID" != "None" ]; then
    SG_ID=$(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPC_ID" "Name=group-name,Values=toogle-master-sg" --query 'SecurityGroups[0].GroupId' --output text 2>/dev/null)
else
    SG_ID=$(aws ec2 describe-security-groups --group-names "toogle-master-sg" --query 'SecurityGroups[0].GroupId' --output text 2>/dev/null)
fi

if [ "$SG_ID" == "None" ] || [ -z "$SG_ID" ]; then
    echo "Error: Security Group 'toogle-master-sg' not found. Run networking.sh first."
    exit 1
fi

echo "Using Security Group: $SG_ID"
echo "Creating RDS Postgres Instance: auth-db..."
aws rds create-db-instance \
    --db-instance-identifier auth-db \
    --db-instance-class db.t3.medium \
    --engine postgres \
    --allocated-storage 20 \
    --master-username "dbuser" \
    --master-user-password "$PASSWORD" \
    --backup-retention-period 7 \
    --publicly-accessible \
    --vpc-security-group-ids "$SG_ID" \
    --db-subnet-group-name "toogle-db-subnet-group" \
    --tags Key=Project,Value=ToogleMaster Key=Service,Value=Auth

echo "Creating RDS Postgres Instance: main-db..."
aws rds create-db-instance \
    --db-instance-identifier main-db \
    --db-instance-class db.t3.medium \
    --engine postgres \
    --allocated-storage 20 \
    --master-username "dbuser" \
    --master-user-password "$PASSWORD" \
    --backup-retention-period 7 \
    --publicly-accessible \
    --vpc-security-group-ids "$SG_ID" \
    --db-subnet-group-name "toogle-db-subnet-group" \
    --tags Key=Project,Value=ToogleMaster Key=Service,Value=Core
