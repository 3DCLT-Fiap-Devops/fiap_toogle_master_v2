#!/bin/bash

# Master script to delete all provisioned AWS resources for ToogleMaster
# WARNING: This will permanently delete your data and infrastructure.

echo "!!! WARNING: Starting AWS Infrastructure Destruction for ToogleMaster !!!"
read -p "Are you sure you want to delete everything? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo "Deletion cancelled."
    exit 1
fi

# 1. Delete RDS Instances
echo "Deleting RDS Instances (auth-db, main-db)..."
aws rds delete-db-instance --db-instance-identifier auth-db --skip-final-snapshot
aws rds delete-db-instance --db-instance-identifier main-db --skip-final-snapshot

# 2. Delete ECR Repositories
SERVICES=("analytics-service" "auth-service" "evaluation-service" "flag-service" "targeting-service")
for service in "${SERVICES[@]}"; do
    echo "Deleting ECR repository: $service..."
    aws ecr delete-repository --repository-name "$service" --force
done

# 3. Delete SQS Queue
echo "Deleting SQS Queue: toogle-events..."
# We need the URL to delete, or we can use the name if we query it
QUEUE_URL=$(aws sqs get-queue-url --queue-name toogle-events --query 'QueueUrl' --output text 2>/dev/null)
if [ ! -z "$QUEUE_URL" ]; then
    aws sqs delete-queue --queue-url "$QUEUE_URL"
fi

# 4. Delete DynamoDB Table
echo "Deleting DynamoDB Table: analytics_events..."
aws dynamodb delete-table --table-name analytics_events

# 5. Delete ElastiCache Redis
echo "Deleting ElastiCache Redis Cluster: toogle-redis..."
aws elasticache delete-cache-cluster --cache-cluster-id toogle-redis

# 6. Delete Networking Resources (Dedicated VPC)
echo "Cleaning up networking resources..."

# Fetch VPC ID
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=toogle-vpc" --query 'Vpcs[0].VpcId' --output text 2>/dev/null)

if [ ! -z "$VPC_ID" ] && [ "$VPC_ID" != "None" ]; then
    echo "Found VPC: $VPC_ID. Starting teardown..."

    # Delete Subnet Groups (RDS and Redis)
    echo "Deleting Subnet Groups..."
    aws rds delete-db-subnet-group --db-subnet-group-name "toogle-db-subnet-group" 2>/dev/null
    aws elasticache delete-cache-subnet-group --cache-subnet-group-name "toogle-cache-subnet-group" 2>/dev/null

    # Delete Security Group
    SG_ID=$(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPC_ID" "Name=group-name,Values=toogle-master-sg" --query 'SecurityGroups[0].GroupId' --output text 2>/dev/null)
    if [ ! -z "$SG_ID" ] && [ "$SG_ID" != "None" ]; then
        echo "Deleting Security Group: $SG_ID"
        aws ec2 delete-security-group --group-id "$SG_ID"
    fi

    # Delete Subnets
    SUBNET_IDS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query 'Subnets[*].SubnetId' --output text)
    for sid in $SUBNET_IDS; do
        echo "Deleting Subnet: $sid"
        aws ec2 delete-subnet --subnet-id "$sid"
    done

    # Delete Route Tables (non-main)
    RT_IDS=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_ID" --query 'RouteTables[?Associations[0].Main!=`true`].RouteTableId' --output text)
    for rtid in $RT_IDS; do
        echo "Deleting Route Table: $rtid"
        aws ec2 delete-route-table --route-table-id "$rtid"
    done

    # Detach and Delete Internet Gateway
    IGW_ID=$(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPC_ID" --query 'InternetGateways[0].InternetGatewayId' --output text 2>/dev/null)
    if [ ! -z "$IGW_ID" ] && [ "$IGW_ID" != "None" ]; then
        echo "Detaching and Deleting IGW: $IGW_ID"
        aws ec2 detach-internet-gateway --internet-gateway-id "$IGW_ID" --vpc-id "$VPC_ID"
        aws ec2 delete-internet-gateway --internet-gateway-id "$IGW_ID"
    fi

    # Finally, Delete VPC
    echo "Deleting VPC: $VPC_ID"
    aws ec2 delete-vpc --vpc-id "$VPC_ID"
else
    echo "Dedicated VPC 'toogle-vpc' not found. Skipping networking cleanup."
fi

# 7. Clean up local files
echo "Cleaning up local files..."
rm -f deployment-summary.txt

echo "Deletion requests sent. Resources may take a few minutes to be fully removed."
