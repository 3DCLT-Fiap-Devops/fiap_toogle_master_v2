#!/bin/bash

# Script to gather AWS resource information and generate k8s/.env.* config files for Kustomize

echo "--------------------------------------------------------"
echo "ToogleMaster K8s Env Files Generator"
echo "--------------------------------------------------------"

# 1. Gather AWS Context
REGION=$(aws configure get region)
REGION=${REGION:-us-east-1}
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null)

if [ -z "$ACCOUNT_ID" ]; then
    echo "Error: Could not determine AWS Account ID. Are you logged in?"
    exit 1
fi

ECR_URL="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

echo "Detected Account ID: ${ACCOUNT_ID}"
echo "Detected Region: ${REGION}"

# 2. Gather Resource Endpoints
echo "Fetching resource endpoints (this may take a moment)..."

# SQS
SQS_URL=$(aws sqs get-queue-url --queue-name toogle-events --query 'QueueUrl' --output text 2>/dev/null)
if [ -z "$SQS_URL" ] || [ "$SQS_URL" == "None" ] || [ "$SQS_URL" == "" ]; then
    SQS_URL="https://sqs.${REGION}.amazonaws.com/${ACCOUNT_ID}/toogle-events"
fi

# Redis (ElastiCache)
REDIS_ENDPOINT=$(aws elasticache describe-cache-clusters \
    --cache-cluster-id toogle-redis \
    --show-cache-node-info \
    --query 'CacheClusters[0].CacheNodes[0].Endpoint.Address' \
    --output text 2>/dev/null)
REDIS_ENDPOINT=${REDIS_ENDPOINT:-"<REDIS_ENDPOINT_NOT_READY>"}

REDIS_PORT=$(aws elasticache describe-cache-clusters \
    --cache-cluster-id toogle-redis \
    --show-cache-node-info \
    --query 'CacheClusters[0].CacheNodes[0].Endpoint.Port' \
    --output text 2>/dev/null)
if [ -z "$REDIS_PORT" ] || [ "$REDIS_PORT" == "None" ] || [ "$REDIS_PORT" == "" ]; then
    REDIS_PORT="6379"
fi
REDIS_URL="redis://${REDIS_ENDPOINT}:${REDIS_PORT}"

# RDS Endpoints
AUTH_DB_ENDPOINT=$(aws rds describe-db-instances --db-instance-identifier auth-db --query 'DBInstances[0].Endpoint.Address' --output text 2>/dev/null)
AUTH_DB_ENDPOINT=${AUTH_DB_ENDPOINT:-"<AUTH_DB_NOT_READY>"}

MAIN_DB_ENDPOINT=$(aws rds describe-db-instances --db-instance-identifier main-db --query 'DBInstances[0].Endpoint.Address' --output text 2>/dev/null)
MAIN_DB_ENDPOINT=${MAIN_DB_ENDPOINT:-"<MAIN_DB_NOT_READY>"}

TARGETING_DB_ENDPOINT=$(aws rds describe-db-instances --db-instance-identifier targeting-db --query 'DBInstances[0].Endpoint.Address' --output text 2>/dev/null)
TARGETING_DB_ENDPOINT=${TARGETING_DB_ENDPOINT:-"<TARGETING_DB_NOT_READY>"}

DB_USER="dbuser"
DB_PASS="SenhaTeste123"

# K8s Directory Path
K8S_DIR="k8s"
if [ ! -d "$K8S_DIR" ]; then
    K8S_DIR="../k8s"
fi

echo "Writing Kustomize .env files to $K8S_DIR/..."

# 1. k8s/auth.env
cat <<EOF > "$K8S_DIR/auth.env"
DATABASE_URL=postgres://$DB_USER:$DB_PASS@$AUTH_DB_ENDPOINT:5432/auth_db
MASTER_KEY=sua_chave_mestra_aqui
EOF
echo "Generated $K8S_DIR/auth.env"

# 2. k8s/flag.env
cat <<EOF > "$K8S_DIR/flag.env"
DATABASE_URL=postgres://$DB_USER:$DB_PASS@$MAIN_DB_ENDPOINT:5432/flag_db
EOF
echo "Generated $K8S_DIR/flag.env"

# 3. k8s/targeting.env
cat <<EOF > "$K8S_DIR/targeting.env"
DATABASE_URL=postgres://$DB_USER:$DB_PASS@$TARGETING_DB_ENDPOINT:5432/targeting_db
EOF
echo "Generated $K8S_DIR/targeting.env"

# 4. k8s/evaluation.env
cat <<EOF > "$K8S_DIR/evaluation.env"
REDIS_URL=$REDIS_URL
AWS_SQS_URL=$SQS_URL
SERVICE_API_KEY=tm_key_f54b81bc161a5b84c277ed954384ae950c87adb8c795892db4abfaef75aaacab
EOF
echo "Generated $K8S_DIR/evaluation.env"

# 5. k8s/analytics.env
cat <<EOF > "$K8S_DIR/analytics.env"
AWS_SQS_URL=$SQS_URL
EOF
echo "Generated $K8S_DIR/analytics.env"

echo "--------------------------------------------------------"
echo "All Kustomize .env configuration files generated successfully!"
echo "--------------------------------------------------------"
