#!/bin/bash

# Master script to provision all AWS resources
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Disable AWS CLI pager to prevent blocking execution
export AWS_PAGER=""

echo "Starting AWS Infrastructure Provisioning for ToogleMaster..."

chmod +x "$SCRIPT_DIR/modules/"*.sh

"$SCRIPT_DIR/modules/networking.sh"
"$SCRIPT_DIR/modules/ecr.sh"
"$SCRIPT_DIR/modules/rds.sh"
"$SCRIPT_DIR/modules/sqs.sh"
"$SCRIPT_DIR/modules/dynamodb.sh"
"$SCRIPT_DIR/modules/redis.sh"
# "$SCRIPT_DIR/modules/eks.sh"

echo "Provisioning requests sent. Please monitor the AWS Console for completion status."
