#!/bin/bash

# Deployment Helper - Bridges Terraform with Seeding and K8s Patching
# This script reads Terraform outputs and runs the necessary post-provisioning tasks.

set -e

echo "--------------------------------------------------------"
echo "ToogleMaster Post-Provisioning Helper"
echo "--------------------------------------------------------"

# 1. Check if terraform has outputs
if ! terraform output > /dev/null 2>&1; then
    echo "Error: No Terraform outputs found. Did you run 'terraform apply'?"
    exit 1
fi

echo "Fetching configuration from Terraform..."

# Extracting values from Terraform outputs
REGION=$(terraform output -raw region 2>/dev/null || echo "us-east-1")
AUTH_DB_ENDPOINT=$(terraform output -raw rds_auth_endpoint | cut -d: -f1)
MAIN_DB_ENDPOINT=$(terraform output -raw rds_main_endpoint | cut -d: -f1)
REDIS_URL="redis://$(terraform output -raw redis_endpoint):6379"
SQS_URL=$(terraform output -raw sqs_url)
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_URL="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"
DB_USER="dbuser"
DB_PASS=$(terraform output -raw db_password 2>/dev/null || echo "SenhaTeste123")

# Generate a temporary deployment-summary.txt compatible with existing scripts
OUTPUT_FILE="../deployment-summary.txt"

# Function to encode to base64
encode_base64() {
    echo -n "$1" | base64 -w 0 2>/dev/null || echo -n "$1" | base64
}

echo "Generating $OUTPUT_FILE for compatibility..."

cat <<EOF > $OUTPUT_FILE
========================================================
TOOGLEMASTER DEPLOYMENT CONFIGURATION SUMMARY (FROM TERRAFORM)
Generated on: $(date)
========================================================

--- AWS CONTEXT ---
Region: $REGION
Account ID: $ACCOUNT_ID
ECR Registry: $ECR_URL

--- RESOURCE ENDPOINTS ---
SQS Queue URL: $SQS_URL
DynamoDB Table: analytics_events
Redis URL: $REDIS_URL
RDS Auth-DB Endpoint: $AUTH_DB_ENDPOINT
RDS Main-DB Endpoint: $MAIN_DB_ENDPOINT

--- MICROSERVICE REPOSITORIES ---
Analytics:  $ECR_URL/analytics-service:latest
Auth:       $ECR_URL/auth-service:latest
Evaluation: $ECR_URL/evaluation-service:latest
Flag:       $ECR_URL/flag-service:latest
Targeting:  $ECR_URL/targeting-service:latest

--- KUBERNETES SECRETS (BASE64) ---
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
echo "Summary generated successfully at root."
echo "--------------------------------------------------------"

# 2. Options for Seeding and Patching
echo "What would you like to do next?"
echo "1) Build and Push Docker images to ECR"
echo "2) Seed Databases (RDS)"
echo "3) Patch K8s Manifests (Base64)"
echo "4) All of the above"
echo "5) Exit"
read -p "Select an option [1-5]: " OPT

# Get the root directory of the project
ROOT_DIR=$(cd ".." && pwd)

case $OPT in
    1) 
        cd "$ROOT_DIR/aws-infra/modules" && ./build-and-push.sh
        ;;
    2) 
        cd "$ROOT_DIR/aws-infra" && ./seed-databases.sh
        ;;
    3) 
        cd "$ROOT_DIR/aws-infra" && ./apply-k8s-patches.sh
        ;;
    4) 
        cd "$ROOT_DIR/aws-infra/modules" && ./build-and-push.sh
        cd "$ROOT_DIR/aws-infra" && ./seed-databases.sh
        cd "$ROOT_DIR/aws-infra" && ./apply-k8s-patches.sh
        ;;
    *) exit 0 ;;
esac

echo "--------------------------------------------------------"
echo "Process completed!"
echo "--------------------------------------------------------"
