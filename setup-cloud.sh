#!/bin/bash

# Master Setup Script for ToogleMaster AWS Infrastructure
# Provisions with Terraform and deploys application config using Kustomize in one go.

set -e
git submodule update --init --recursive
echo "========================================================"
echo "STARTING FULL AWS PROVISIONING AND DEPLOYMENT"
echo "========================================================"

# 1. Infrastructure with Terraform
echo "Step 1: Provisioning Infrastructure with Terraform..."
cd terraform
terraform init
terraform apply -auto-approve

# 2. Application Deployment Tasks
echo "Step 2: Running Post-Provisioning Tasks (Build, Seed, Kustomize)..."
ROOT_DIR=$(cd ".." && pwd)

# Generate the K8s .env files from Terraform outputs
./deploy-helper.sh <<EOF
5
EOF

# Build and Push ECR Docker images
echo "Building and Pushing images..."
cd "$ROOT_DIR/aws-infra/modules" && sh build-and-push.sh

# Seed Databases (reads endpoints directly from k8s/*.env)
echo "Seeding databases..."
cd "$ROOT_DIR/aws-infra" && sh seed-databases.sh

# Configure credentials and deploy EKS using Kustomize
echo "========================================================"
echo "INFRASTRUCTURE AND CONFIGURATION COMPLETE!"
echo "========================================================"
echo "Deploying to EKS via Kustomize..."

# Update EKS Kubeconfig
aws eks update-kubeconfig --region us-east-1 --name toogle-cluster

# Run Kustomize deploy script (generates secrets and applies kubectl apply -k)
cd "$ROOT_DIR" && python deploy-credentials.py

echo "Setup complete. You can access the application via the LoadBalancer DNS."
