#!/bin/bash

# CryptoSpins API Build and Deploy Script
set -e

# Configuration
ECR_REPOSITORY="269599744150.dkr.ecr.us-east-1.amazonaws.com/cryptospins-api"
AWS_REGION="us-east-1"
IMAGE_TAG="${1:-latest}"

echo "🎰 Building CryptoSpins API..."
echo "Repository: $ECR_REPOSITORY"
echo "Tag: $IMAGE_TAG"
echo "Region: $AWS_REGION"

# Check if we're in the right directory
if [ ! -f "Dockerfile" ]; then
    echo "❌ Error: Dockerfile not found. Please run this script from the api/ directory."
    exit 1
fi

# Build the Docker image
echo "🔨 Building Docker image..."
docker build -t cryptospins-api:$IMAGE_TAG .

# Login to ECR
echo "🔐 Logging into ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPOSITORY

# Tag for ECR
echo "🏷️  Tagging image for ECR..."
docker tag cryptospins-api:$IMAGE_TAG $ECR_REPOSITORY:$IMAGE_TAG

# Push to ECR
echo "⬆️  Pushing to ECR..."
docker push $ECR_REPOSITORY:$IMAGE_TAG

echo "✅ Successfully built and pushed CryptoSpins API!"
echo "📦 Image: $ECR_REPOSITORY:$IMAGE_TAG"
echo ""
echo "Next steps:"
echo "1. Ensure ArgoCD application is synced: kubectl get app cryptospins-api -n argocd"
echo "2. Check pod status: kubectl get pods -l app=cryptospins-api"
echo "3. Get service URL: kubectl get svc cryptospins-api"