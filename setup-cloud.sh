#!/bin/bash

# Master Setup Script for ToogleMaster AWS Infrastructure
# Provisions with Terraform and deploys application config in one go.

set -e

echo "========================================================"
echo "STARTING FULL AWS PROVISIONING AND DEPLOYMENT"
echo "========================================================"

# 1. Infrastructure with Terraform
echo "Step 1: Provisioning Infrastructure with Terraform..."
cd terraform
terraform init
terraform apply -auto-approve

# 2. Application Deployment Tasks
echo "Step 2: Running Post-Provisioning Tasks (Build, Seed, Patch)..."
# We bypass the interactive menu of deploy-helper.sh by calling the steps directly
ROOT_DIR=$(cd ".." && pwd)

# Generate the summary first
./deploy-helper.sh <<EOF
5
EOF

# Manually trigger the steps in sequence
echo "Building and Pushing images..."
cd "$ROOT_DIR/aws-infra/modules" && sh build-and-push.sh

echo "Seeding databases..."
cp "$ROOT_DIR/deployment-summary.txt" "$ROOT_DIR/aws-infra/deployment-summary.txt"
cd "$ROOT_DIR/aws-infra" && sh seed-databases.sh

echo "Patching K8s manifests..."
sh apply-k8s-patches.sh

aws eks update-kubeconfig --region us-east-1 --name toogle-cluster

echo "========================================================"
echo "INFRASTRUCTURE AND CONFIGURATION COMPLETE!"
echo "========================================================"
echo "You can now deploy to EKS using: kubectl apply -f k8s/"
