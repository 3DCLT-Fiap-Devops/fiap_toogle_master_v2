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


# Caso vá rodar localmente, basta comentar as linhas abaixo e usar o kubectl localmente
aws eks update-kubeconfig --region us-east-1 --name toogle-cluster
# kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/aws/deploy.yaml # Instalação do Ingress Controller para AWS

echo "========================================================"
echo "INFRASTRUCTURE AND CONFIGURATION COMPLETE!"
echo "========================================================"
echo "Deploying to EKS..."
kubectl apply -f "$ROOT_DIR/k8s/namespace.yaml"
kubectl apply -f "$ROOT_DIR/k8s/"

echo "Setup complete. You can access the application via the LoadBalancer DNS."
