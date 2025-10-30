#!/bin/bash

# GitHub Actions OIDC Setup Script for AWS
set -e

ROLE_NAME="github-actions-terraform-role"
OIDC_PROVIDER_ARN=""
GITHUB_REPO="lolearningcode/high-stakes-devops"
ECHO_COLOR="\033[1;36m"  # Cyan
SUCCESS_COLOR="\033[1;32m"  # Green
ERROR_COLOR="\033[1;31m"  # Red
NC="\033[0m"  # No Color

echo -e "${ECHO_COLOR}🔐 GitHub Actions OIDC Setup for AWS${NC}"
echo "=========================================="

# Check if AWS CLI is configured
if ! aws sts get-caller-identity >/dev/null 2>&1; then
    echo -e "${ERROR_COLOR}❌ AWS CLI not configured. Run 'aws configure' first.${NC}"
    exit 1
fi

ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
echo -e "${ECHO_COLOR}📋 AWS Account ID: ${ACCOUNT_ID}${NC}"

# Step 1: Create OIDC Identity Provider (if it doesn't exist)
echo -e "${ECHO_COLOR}🌐 Setting up GitHub OIDC Identity Provider...${NC}"

# Check if OIDC provider already exists
if aws iam list-open-id-connect-providers --query 'OpenIDConnectProviderList[?ends_with(Arn, `token.actions.githubusercontent.com`)]' --output text | grep -q "token.actions.githubusercontent.com"; then
    echo "✅ GitHub OIDC provider already exists"
    OIDC_PROVIDER_ARN="arn:aws:iam::${ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"
else
    echo "Creating GitHub OIDC provider..."
    
    # Download GitHub's OIDC thumbprint
    THUMBPRINT="6938fd4d98bab03faadb97b34396831e3780aea1"
    
    # Create OIDC provider
    OIDC_PROVIDER_ARN=$(aws iam create-open-id-connect-provider \
        --url https://token.actions.githubusercontent.com \
        --thumbprint-list $THUMBPRINT \
        --client-id-list sts.amazonaws.com \
        --query 'OpenIDConnectProviderArn' \
        --output text)
    
    echo "✅ Created OIDC provider: $OIDC_PROVIDER_ARN"
fi

# Step 2: Create Trust Policy for the IAM Role
echo -e "${ECHO_COLOR}📝 Creating trust policy...${NC}"

cat > /tmp/github-trust-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "$OIDC_PROVIDER_ARN"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
                },
                "StringLike": {
                    "token.actions.githubusercontent.com:sub": "repo:${GITHUB_REPO}:*"
                }
            }
        }
    ]
}
EOF

# Step 3: Create IAM Role (or update if exists)
echo -e "${ECHO_COLOR}👤 Setting up IAM role: ${ROLE_NAME}${NC}"

if aws iam get-role --role-name "$ROLE_NAME" >/dev/null 2>&1; then
    echo "Role already exists, updating trust policy..."
    aws iam update-assume-role-policy \
        --role-name "$ROLE_NAME" \
        --policy-document file:///tmp/github-trust-policy.json
else
    echo "Creating new role..."
    aws iam create-role \
        --role-name "$ROLE_NAME" \
        --assume-role-policy-document file:///tmp/github-trust-policy.json \
        --description "IAM role for GitHub Actions OIDC authentication"
fi

# Step 4: Create and attach permissions policy
echo -e "${ECHO_COLOR}🔑 Setting up permissions policy...${NC}"

cat > /tmp/github-terraform-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:*",
                "eks:*",
                "iam:*",
                "s3:*",
                "dynamodb:*",
                "ecr:*",
                "logs:*",
                "autoscaling:*",
                "elasticloadbalancing:*",
                "route53:*",
                "acm:*",
                "kms:*",
                "secretsmanager:*",
                "ssm:*",
                "sts:*"
            ],
            "Resource": "*"
        }
    ]
}
EOF

POLICY_NAME="github-actions-terraform-policy"

# Check if policy exists
POLICY_ARN="arn:aws:iam::${ACCOUNT_ID}:policy/${POLICY_NAME}"

if aws iam get-policy --policy-arn "$POLICY_ARN" >/dev/null 2>&1; then
    echo "Policy already exists, creating new version..."
    aws iam create-policy-version \
        --policy-arn "$POLICY_ARN" \
        --policy-document file:///tmp/github-terraform-policy.json \
        --set-as-default
else
    echo "Creating new policy..."
    POLICY_ARN=$(aws iam create-policy \
        --policy-name "$POLICY_NAME" \
        --policy-document file:///tmp/github-terraform-policy.json \
        --description "Policy for GitHub Actions Terraform operations" \
        --query 'Policy.Arn' \
        --output text)
fi

# Attach policy to role
echo "Attaching policy to role..."
aws iam attach-role-policy \
    --role-name "$ROLE_NAME" \
    --policy-arn "$POLICY_ARN"

# Clean up temporary files
rm -f /tmp/github-trust-policy.json /tmp/github-terraform-policy.json

echo
echo -e "${SUCCESS_COLOR}✅ OIDC Setup Complete!${NC}"
echo "=========================================="
echo
echo -e "${ECHO_COLOR}📋 Configuration Summary:${NC}"
echo "• OIDC Provider: $OIDC_PROVIDER_ARN"
echo "• IAM Role: arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME}"
echo "• Policy: $POLICY_ARN"
echo "• GitHub Repository: ${GITHUB_REPO}"
echo
echo -e "${ECHO_COLOR}🔍 Verification Commands:${NC}"
echo "aws iam get-role --role-name $ROLE_NAME"
echo "aws iam list-attached-role-policies --role-name $ROLE_NAME"
echo
echo -e "${SUCCESS_COLOR}🎉 Your GitHub Actions workflows can now authenticate with AWS using OIDC!${NC}"
echo
echo -e "${ECHO_COLOR}ℹ️  Note: No GitHub secrets needed - OIDC handles authentication automatically.${NC}"