#!/bin/bash

# Deployment Helper - Bridges Terraform with Seeding and K8s Kustomize
# This script reads Terraform outputs and generates K8s .env files.

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
TARGETING_DB_ENDPOINT=$(terraform output -raw rds_targeting_endpoint | cut -d: -f1)
REDIS_URL="redis://$(terraform output -raw redis_endpoint):6379"
SQS_URL=$(terraform output -raw sqs_url)
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "112719111297")
DB_USER="dbuser"
DB_PASS=$(terraform output -raw db_password 2>/dev/null || echo "SenhaTeste123")

# K8s Directory Path
K8S_DIR="../k8s"

echo "Generating Kustomize .env configuration files in $K8S_DIR..."

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
echo "All K8s configuration .env files generated successfully!"
echo "--------------------------------------------------------"

# 2. Options for Seeding and Patching
echo "What would you like to do next?"
echo "1) Build and Push Docker images to ECR"
echo "2) Seed Databases (RDS)"
echo "3) Update AWS Credentials & Deploy to EKS (Kustomize)"
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
        cd "$ROOT_DIR" && python deploy-credentials.py
        ;;
    4) 
        cd "$ROOT_DIR/aws-infra/modules" && ./build-and-push.sh
        cd "$ROOT_DIR/aws-infra" && ./seed-databases.sh
        cd "$ROOT_DIR" && python deploy-credentials.py
        ;;
    *) exit 0 ;;
esac

echo "--------------------------------------------------------"
echo "Process completed!"
echo "--------------------------------------------------------"
