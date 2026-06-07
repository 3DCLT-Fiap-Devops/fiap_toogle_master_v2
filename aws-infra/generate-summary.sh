#!/bin/bash

# Script to generate a consolidated configuration summary for ToogleMaster
# It gathers AWS resource information and generates K8s-ready secrets (Base64)

OUTPUT_FILE="deployment-summary.txt"

echo "--------------------------------------------------------"
echo "ToogleMaster Configuration Generator"
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

# 2. Gather Resource Endpoints (Try to fetch if they exist)
echo "Fetching resource endpoints (this may take a moment)..."

# SQS
SQS_URL=$(aws sqs get-queue-url --queue-name toogle-events --query 'QueueUrl' --output text 2>/dev/null)
SQS_URL=${SQS_URL:-"<SQS_URL_NOT_FOUND>"}

# DynamoDB
DYNAMO_TABLE="analytics_events"

# Redis (ElastiCache)
REDIS_ENDPOINT=$(aws elasticache describe-cache-clusters \
    --cache-cluster-id toogle-redis \
    --show-cache-node-info \
    --query 'CacheClusters[0].CacheNodes[0].Endpoint.Address' \
    --output text 2>/dev/null)
REDIS_PORT=$(aws elasticache describe-cache-clusters \
    --cache-cluster-id toogle-redis \
    --show-cache-node-info \
    --query 'CacheClusters[0].CacheNodes[0].Endpoint.Port' \
    --output text 2>/dev/null)
REDIS_URL="redis://${REDIS_ENDPOINT}:${REDIS_PORT}"

# RDS Endpoints
AUTH_DB_ENDPOINT=$(aws rds describe-db-instances --db-instance-identifier auth-db --query 'DBInstances[0].Endpoint.Address' --output text 2>/dev/null)
AUTH_DB_ENDPOINT=${AUTH_DB_ENDPOINT:-"<AUTH_DB_NOT_READY>"}

MAIN_DB_ENDPOINT=$(aws rds describe-db-instances --db-instance-identifier main-db --query 'DBInstances[0].Endpoint.Address' --output text 2>/dev/null)
MAIN_DB_ENDPOINT=${MAIN_DB_ENDPOINT:-"<MAIN_DB_NOT_READY>"}

DB_USER="dbuser"
DB_PASS="SenhaTeste123" # Matching rds.sh

# Function to encode to base64 without line wrapping
encode_base64() {
    echo -n "$1" | base64 -w 0 2>/dev/null || echo -n "$1" | base64
}

# 3. Generate the Summary File
cat <<EOF > $OUTPUT_FILE
========================================================
TOOGLEMASTER DEPLOYMENT CONFIGURATION SUMMARY
Generated on: $(date)
========================================================

--- AWS CONTEXT ---
Region: $REGION
Account ID: $ACCOUNT_ID
ECR Registry: $ECR_URL

--- RESOURCE ENDPOINTS ---
SQS Queue URL: $SQS_URL
DynamoDB Table: $DYNAMO_TABLE
Redis URL: $REDIS_URL
RDS Auth-DB Endpoint: $AUTH_DB_ENDPOINT
RDS Main-DB Endpoint: $MAIN_DB_ENDPOINT

--- MICROSERVICE REPOSITORIES ---
Analytics:  $ECR_URL/analytics-service:latest
Auth:       $ECR_URL/auth-service:latest
Evaluation: $ECR_URL/evaluation-service:latest
Flag:       $ECR_URL/flag-service:latest
Targeting:  $ECR_URL/targeting-service:latest

--- DATABASE NAMES ---
(Make sure these are created inside your RDS instances)
Auth Service:      auth_db      (Instance: auth-db)
Flag Service:      flag_db      (Instance: main-db)
Targeting Service: targeting_db (Instance: main-db)

--- MANUAL DATABASE SETUP ---
You can create the databases using psql (or any DB client):
1. Connect to Auth Instance:
   psql -h $AUTH_DB_ENDPOINT -U $DB_USER -d postgres -c "CREATE DATABASE auth_db;"

2. Connect to Main Instance:
   psql -h $MAIN_DB_ENDPOINT -U $DB_USER -d postgres -c "CREATE DATABASE flag_db;"
   psql -h $MAIN_DB_ENDPOINT -U $DB_USER -d postgres -c "CREATE DATABASE targeting_db;"

--- KUBERNETES SECRETS (BASE64) ---
Use these values in your K8s Secret manifests or via kubectl.

1. Auth Service Secret:
   DATABASE_URL: $(encode_base64 "postgres://$DB_USER:$DB_PASS@$AUTH_DB_ENDPOINT:5432/auth_db")
   MASTER_KEY:   $(encode_base64 "sua_chave_mestra_aqui")

2. Flag Service Secret:
   DATABASE_URL: $(encode_base64 "postgres://$DB_USER:$DB_PASS@$MAIN_DB_ENDPOINT:5432/flag_db")

3. Targeting Service Secret:
   DATABASE_URL: $(encode_base64 "postgres://$DB_USER:$DB_PASS@$MAIN_DB_ENDPOINT:5432/targeting_db")

4. Evaluation Service Secret:
   REDIS_URL:       $(encode_base64 "$REDIS_URL")
   AWS_SQS_URL:     $(encode_base64 "$SQS_URL")
   SERVICE_API_KEY: $(encode_base64 "tm_key_f54b81bc161a5b84c277ed954384ae950c87adb8c795892db4abfaef75aaacab")

5. Analytics Service Secret:
   AWS_SQS_URL:     $(encode_base64 "$SQS_URL")

========================================================
EOF

echo "--------------------------------------------------------"
echo "Summary generated successfully: $OUTPUT_FILE"
echo "You can now copy the values from this file."
echo "--------------------------------------------------------"
