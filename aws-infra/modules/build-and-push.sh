#!/bin/bash

# Script to build and push Docker images to AWS ECR

# Config
REGION=$(aws configure get region)
REGION=${REGION:-us-east-1}
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_URL="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

echo "Detected Account ID: ${ACCOUNT_ID}"
echo "Detected Region: ${REGION}"
echo "ECR URL: ${ECR_URL}"

# 1. Authenticate Docker to ECR
echo "Authenticating Docker to ECR..."
aws ecr get-login-password --region "${REGION}" | docker login --username AWS --password-stdin "${ECR_URL}"

# 2. Build and Push images
SERVICES=("analytics-service" "auth-service" "evaluation-service" "flag-service" "targeting-service")

# Map service names to their Dockerfile locations (in the project root)
declare -A DOCKERFILES
DOCKERFILES["analytics-service"]="docker/Dockerfile.analytics"
DOCKERFILES["auth-service"]="docker/Dockerfile.auth"
DOCKERFILES["evaluation-service"]="docker/Dockerfile.evaluation"
DOCKERFILES["flag-service"]="docker/Dockerfile.flag"
DOCKERFILES["targeting-service"]="docker/Dockerfile.targeting"

# We run from the project root to ensure build context is correct
cd ..

for service in "${SERVICES[@]}"; do
    echo "--------------------------------------------------------"
    echo "Processing service: $service"
    
    REPO_URI="${ECR_URL}/${service}"
    DOCKERFILE=${DOCKERFILES[$service]}
    
    echo "Building image: $service..."
    docker build -t "$service" -f "$DOCKERFILE" .
    
    echo "Tagging image..."
    docker tag "${service}:latest" "${REPO_URI}:latest"
    
    echo "Pushing image to ECR..."
    docker push "${REPO_URI}:latest"
    
    echo "Finished $service"
done

echo "--------------------------------------------------------"
echo "All images built and pushed successfully!"
