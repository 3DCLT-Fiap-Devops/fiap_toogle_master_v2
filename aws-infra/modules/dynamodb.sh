#!/bin/bash

# DynamoDB Table

echo "Creating DynamoDB Table: analytics_events..."
aws dynamodb create-table \
    --table-name analytics_events \
    --attribute-definitions AttributeName=event_id,AttributeType=S \
    --key-schema AttributeName=event_id,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --tags Key=Project,Value=ToogleMaster
