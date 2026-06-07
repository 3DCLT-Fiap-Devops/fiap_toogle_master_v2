#!/bin/bash

# Script to automatically patch K8s manifests with secrets from deployment-summary.txt
# This is an optional script to avoid manual copy-pasting.

SUMMARY_FILE="deployment-summary.txt"
K8S_DIR="../k8s"

if [ ! -f "$SUMMARY_FILE" ]; then
    echo "Error: $SUMMARY_FILE not found. Run generate-summary.sh first."
    exit 1
fi

echo "Patching K8s manifests with values from $SUMMARY_FILE..."

# Function to extract value from summary and patch a file
patch_secret() {
    local key=$1
    local file=$2
    local search_pattern=$3
    
    # Extract the base64 value from summary (line starting with the key)
    local value=$(grep "$key:" "$SUMMARY_FILE" | awk '{print $2}' | head -n 1)
    
    if [ ! -z "$value" ]; then
        echo "Updating $key in $file..."
        # Use sed to replace the line. We assume the pattern is 'KEY: value'
        sed -i "s|$search_pattern:.*|$search_pattern: $value|g" "$K8S_DIR/$file"
    else
        echo "Warning: Could not find value for $key in summary."
    fi
}

# 1. Auth Service
patch_secret "DATABASE_URL" "auth-service.yaml" "DATABASE_URL"
# Note: MASTER_KEY in summary might be the first one found. Auth needs it.
AUTH_MASTER_KEY=$(grep -A 2 "1. Auth Service Secret" "$SUMMARY_FILE" | grep "MASTER_KEY" | awk '{print $2}')
if [ ! -z "$AUTH_MASTER_KEY" ]; then
    sed -i "s|MASTER_KEY:.*|MASTER_KEY: $AUTH_MASTER_KEY|g" "$K8S_DIR/auth-service.yaml"
fi

# 2. Flag Service
# We need to be careful because multiple services use DATABASE_URL. 
# In the simple YAML files, we'll target them specifically.
FLAG_DB=$(grep -A 1 "2. Flag Service Secret" "$SUMMARY_FILE" | grep "DATABASE_URL" | awk '{print $2}')
if [ ! -z "$FLAG_DB" ]; then
    sed -i "s|DATABASE_URL:.*|DATABASE_URL: $FLAG_DB|g" "$K8S_DIR/flag-service.yaml"
fi

# 3. Targeting Service
TARGET_DB=$(grep -A 1 "3. Targeting Service Secret" "$SUMMARY_FILE" | grep "DATABASE_URL" | awk '{print $2}')
if [ ! -z "$TARGET_DB" ]; then
    sed -i "s|DATABASE_URL:.*|DATABASE_URL: $TARGET_DB|g" "$K8S_DIR/targeting-service.yaml"
fi

# 4. Evaluation Service
EVAL_REDIS=$(grep -A 3 "4. Evaluation Service Secret" "$SUMMARY_FILE" | grep "REDIS_URL" | awk '{print $2}')
EVAL_SQS=$(grep -A 3 "4. Evaluation Service Secret" "$SUMMARY_FILE" | grep "AWS_SQS_URL" | awk '{print $2}')
EVAL_API=$(grep -A 3 "4. Evaluation Service Secret" "$SUMMARY_FILE" | grep "SERVICE_API_KEY" | awk '{print $2}')

if [ ! -z "$EVAL_REDIS" ]; then sed -i "s|REDIS_URL:.*|REDIS_URL: $EVAL_REDIS|g" "$K8S_DIR/evaluation-service.yaml"; fi
if [ ! -z "$EVAL_SQS" ]; then sed -i "s|AWS_SQS_URL:.*|AWS_SQS_URL: $EVAL_SQS|g" "$K8S_DIR/evaluation-service.yaml"; fi
if [ ! -z "$EVAL_API" ]; then sed -i "s|SERVICE_API_KEY:.*|SERVICE_API_KEY: $EVAL_API|g" "$K8S_DIR/evaluation-service.yaml"; fi

# 5. Analytics Service
ANAL_SQS=$(grep -A 1 "5. Analytics Service Secret" "$SUMMARY_FILE" | grep "AWS_SQS_URL" | awk '{print $2}')
if [ ! -z "$ANAL_SQS" ]; then
    sed -i "s|AWS_SQS_URL:.*|AWS_SQS_URL: $ANAL_SQS|g" "$K8S_DIR/analytics-service.yaml"
fi

# 6. Patching ACCOUNT_ID in all deployments
ACCOUNT_ID=$(grep "Account ID:" "$SUMMARY_FILE" | awk '{print $3}')
if [ ! -z "$ACCOUNT_ID" ]; then
    echo "Updating ACCOUNT_ID to $ACCOUNT_ID in all K8s manifests..."
    sed -i "s|<ACCOUNT_ID>|$ACCOUNT_ID|g" $K8S_DIR/*.yaml
fi

echo "--------------------------------------------------------"
echo "Patching complete! Your K8s manifests in /k8s are ready."
echo "Note: Helm chart values (if used) were not patched by this script."
echo "--------------------------------------------------------"
