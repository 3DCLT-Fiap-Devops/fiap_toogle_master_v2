#!/bin/bash

# ElastiCache Redis Cluster
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
echo "Creating ElastiCache Redis Cluster: toogle-redis..."
aws elasticache create-cache-cluster \
    --cache-cluster-id toogle-redis \
    --engine redis \
    --cache-node-type cache.t3.medium \
    --num-cache-nodes 1 \
    --security-group-ids "$SG_ID" \
    --cache-subnet-group-name "toogle-cache-subnet-group" \
    --tags Key=Project,Value=ToogleMaster
