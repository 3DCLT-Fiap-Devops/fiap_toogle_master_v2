#!/bin/bash

# ECR Repositories for each microservice

SERVICES=("analytics-service" "auth-service" "evaluation-service" "flag-service" "targeting-service")

for service in "${SERVICES[@]}"; do
    echo "Creating ECR repository: $service..."
    aws ecr create-repository \
        --repository-name "$service" \
        --image-scanning-configuration scanOnPush=true \
        --tags Key=Project,Value=ToogleMaster
done
