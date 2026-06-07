#!/bin/bash

# SQS Queue

echo "Creating SQS Queue: toogle-events..."
aws sqs create-queue \
    --queue-name toogle-events \
    --attributes VisibilityTimeout=30 \
    --tags Project=ToogleMaster
