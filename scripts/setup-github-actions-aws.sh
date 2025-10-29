#!/bin/bash

# GitHub Actions AWS IAM User Setup Script
set -e

USER_NAME="github-actions-cryptospins"
ECHO_COLOR="\033[1;36m"  # Cyan
SUCCESS_COLOR="\033[1;32m"  # Green
ERROR_COLOR="\033[1;31m"  # Red
NC="\033[0m"  # No Color

echo -e "${ECHO_COLOR}🔐 GitHub Actions AWS IAM User Setup${NC}"
echo "========================================"

# Check if AWS CLI is configured
if ! aws sts get-caller-identity >/dev/null 2>&1; then
    echo -e "${ERROR_COLOR}❌ AWS CLI not configured. Run 'aws configure' first.${NC}"
    exit 1
fi

echo -e "${ECHO_COLOR}📋 Current AWS Account:${NC}"
aws sts get-caller-identity --query 'Account' --output text

# Check if user already exists
if aws iam get-user --user-name "$USER_NAME" >/dev/null 2>&1; then
    echo -e "${ERROR_COLOR}❌ User '$USER_NAME' already exists!${NC}"
    echo "Choose an option:"
    echo "1. Use existing user (will create new access key)"
    echo "2. Delete and recreate user"
    echo "3. Exit"
    read -p "Choice (1-3): " choice
    
    case $choice in
        1)
            echo -e "${ECHO_COLOR}📝 Using existing user...${NC}"
            ;;
        2)
            echo -e "${ECHO_COLOR}🗑️  Deleting existing user...${NC}"
            # Delete access keys first
            ACCESS_KEYS=$(aws iam list-access-keys --user-name "$USER_NAME" --query 'AccessKeyMetadata[].AccessKeyId' --output text)
            for key in $ACCESS_KEYS; do
                aws iam delete-access-key --user-name "$USER_NAME" --access-key-id "$key"
            done
            # Detach policies
            aws iam detach-user-policy --user-name "$USER_NAME" --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess 2>/dev/null || true
            aws iam detach-user-policy --user-name "$USER_NAME" --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy 2>/dev/null || true
            # Delete user
            aws iam delete-user --user-name "$USER_NAME"
            ;;
        3)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo -e "${ERROR_COLOR}Invalid choice${NC}"
            exit 1
            ;;
    esac
fi

# Create user if it doesn't exist
if ! aws iam get-user --user-name "$USER_NAME" >/dev/null 2>&1; then
    echo -e "${ECHO_COLOR}👤 Creating IAM user: $USER_NAME${NC}"
    aws iam create-user --user-name "$USER_NAME"
fi

# Attach ECR permissions
echo -e "${ECHO_COLOR}🔑 Attaching ECR permissions...${NC}"
aws iam attach-user-policy \
    --user-name "$USER_NAME" \
    --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess

# Ask about EKS permissions
echo
read -p "Do you want to attach EKS permissions for K8s deployment updates? (y/N): " add_eks
if [[ $add_eks =~ ^[Yy]$ ]]; then
    echo -e "${ECHO_COLOR}🚢 Attaching EKS permissions...${NC}"
    aws iam attach-user-policy \
        --user-name "$USER_NAME" \
        --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy
fi

# Create access key
echo -e "${ECHO_COLOR}🔐 Creating access key...${NC}"
ACCESS_KEY_OUTPUT=$(aws iam create-access-key --user-name "$USER_NAME")

# Parse and display credentials
ACCESS_KEY_ID=$(echo "$ACCESS_KEY_OUTPUT" | jq -r '.AccessKey.AccessKeyId')
SECRET_ACCESS_KEY=$(echo "$ACCESS_KEY_OUTPUT" | jq -r '.AccessKey.SecretAccessKey')

echo
echo -e "${SUCCESS_COLOR}✅ IAM User Created Successfully!${NC}"
echo "========================================"
echo
echo -e "${ECHO_COLOR}📋 GitHub Repository Secrets:${NC}"
echo "Go to: GitHub Repo → Settings → Secrets and variables → Actions"
echo
echo "Add these secrets:"
echo -e "${SUCCESS_COLOR}Name:${NC} AWS_ACCESS_KEY_ID"
echo -e "${SUCCESS_COLOR}Value:${NC} $ACCESS_KEY_ID"
echo
echo -e "${SUCCESS_COLOR}Name:${NC} AWS_SECRET_ACCESS_KEY"  
echo -e "${SUCCESS_COLOR}Value:${NC} $SECRET_ACCESS_KEY"
echo
echo -e "${ERROR_COLOR}⚠️  IMPORTANT: Save these credentials now - the secret key won't be shown again!${NC}"
echo
echo -e "${ECHO_COLOR}🔍 Verification Commands:${NC}"
echo "aws iam get-user --user-name $USER_NAME"
echo "aws iam list-attached-user-policies --user-name $USER_NAME"
echo
echo -e "${SUCCESS_COLOR}🎉 Setup complete! Your GitHub Actions can now push to ECR.${NC}"