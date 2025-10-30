#!/bin/bash

# 🚀 CryptoSpins S3 Backend Setup
# This script sets up S3 backend for Terraform without requiring Terraform Cloud

set -e

echo "🚀 Setting up S3 Backend for CryptoSpins Terraform"
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
if [ $? -ne 0 ]; then
    echo "❌ Error: Could not get AWS account ID. Make sure AWS CLI is configured."
    exit 1
fi

echo -e "${BLUE}📋 AWS Account ID: ${AWS_ACCOUNT_ID}${NC}"
echo ""

# Configuration
BUCKET_NAME="cryptospins-terraform-state-${AWS_ACCOUNT_ID}"
DYNAMODB_TABLE="cryptospins-terraform-locks"
REGION="us-east-1"

echo -e "${BLUE}🗂️  Configuration:${NC}"
echo "   S3 Bucket: ${BUCKET_NAME}"
echo "   DynamoDB Table: ${DYNAMODB_TABLE}"
echo "   Region: ${REGION}"
echo ""

# Step 1: Create S3 bucket if it doesn't exist
echo -e "${YELLOW}📦 Step 1: Creating S3 bucket...${NC}"
if aws s3api head-bucket --bucket "${BUCKET_NAME}" 2>/dev/null; then
    echo "✅ S3 bucket ${BUCKET_NAME} already exists"
else
    aws s3api create-bucket --bucket "${BUCKET_NAME}" --region "${REGION}"
    echo "✅ Created S3 bucket: ${BUCKET_NAME}"
fi

# Enable versioning
echo "🔄 Enabling versioning..."
aws s3api put-bucket-versioning --bucket "${BUCKET_NAME}" --versioning-configuration Status=Enabled
echo "✅ Versioning enabled"

# Enable encryption
echo "🔒 Enabling encryption..."
aws s3api put-bucket-encryption --bucket "${BUCKET_NAME}" --server-side-encryption-configuration '{
    "Rules": [
        {
            "ApplyServerSideEncryptionByDefault": {
                "SSEAlgorithm": "AES256"
            }
        }
    ]
}'
echo "✅ Encryption enabled"

# Block public access
echo "🛡️  Blocking public access..."
aws s3api put-public-access-block --bucket "${BUCKET_NAME}" --public-access-block-configuration '{
    "BlockPublicAcls": true,
    "IgnorePublicAcls": true,
    "BlockPublicPolicy": true,
    "RestrictPublicBuckets": true
}'
echo "✅ Public access blocked"

# Step 2: Create DynamoDB table if it doesn't exist
echo ""
echo -e "${YELLOW}🗄️  Step 2: Creating DynamoDB table...${NC}"
if aws dynamodb describe-table --table-name "${DYNAMODB_TABLE}" --region "${REGION}" 2>/dev/null >/dev/null; then
    echo "✅ DynamoDB table ${DYNAMODB_TABLE} already exists"
else
    aws dynamodb create-table \
        --table-name "${DYNAMODB_TABLE}" \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --region "${REGION}" \
        --tags Key=Name,Value="CryptoSpins Terraform Locks" Key=Purpose,Value="terraform-state-locking" \
        >/dev/null
    
    echo "⏳ Waiting for DynamoDB table to be active..."
    aws dynamodb wait table-exists --table-name "${DYNAMODB_TABLE}" --region "${REGION}"
    echo "✅ Created DynamoDB table: ${DYNAMODB_TABLE}"
fi

# Step 3: Update backend configuration
echo ""
echo -e "${YELLOW}📝 Step 3: Updating backend configuration...${NC}"

# Create backend configuration
cat > terraform/backend-config.hcl << EOF
bucket         = "${BUCKET_NAME}"
key            = "cryptospins/terraform.tfstate"
region         = "${REGION}"
encrypt        = true
dynamodb_table = "${DYNAMODB_TABLE}"
EOF

echo "✅ Created terraform/backend-config.hcl"

# Update backend.tf to enable the S3 backend
sed -i.backup 's/^# terraform {$/terraform {/' terraform/backend.tf
sed -i.backup 's/^#   backend "s3" {$/  backend "s3" {/' terraform/backend.tf
sed -i.backup 's/^#     bucket/    bucket/' terraform/backend.tf
sed -i.backup 's/^#     key/    key/' terraform/backend.tf
sed -i.backup 's/^#     region/    region/' terraform/backend.tf
sed -i.backup 's/^#     encrypt/    encrypt/' terraform/backend.tf
sed -i.backup 's/^#     dynamodb_table/    dynamodb_table/' terraform/backend.tf
sed -i.backup 's/^#   }$/  }/' terraform/backend.tf
sed -i.backup 's/^# }$/}/' terraform/backend.tf

echo "✅ Updated terraform/backend.tf to enable S3 backend"

# Step 4: Initialize Terraform with new backend
echo ""
echo -e "${YELLOW}🏗️  Step 4: Initializing Terraform with S3 backend...${NC}"
cd terraform
terraform init -reconfigure -backend-config=backend-config.hcl
echo "✅ Terraform initialized with S3 backend"

echo ""
echo -e "${GREEN}🎉 S3 Backend Setup Complete!${NC}"
echo ""
echo -e "${BLUE}📋 Summary:${NC}"
echo "   ✅ S3 bucket created and secured: ${BUCKET_NAME}"
echo "   ✅ DynamoDB table created: ${DYNAMODB_TABLE}"
echo "   ✅ Terraform backend configured"
echo "   ✅ State will be stored in S3 with locking"
echo ""
echo -e "${BLUE}🚀 Next Steps:${NC}"
echo "   1. Run 'terraform plan' to verify everything works"
echo "   2. Commit the updated backend.tf file"
echo "   3. Push to GitHub to trigger automated CI/CD"
echo ""
echo -e "${YELLOW}💡 Benefits of S3 Backend:${NC}"
echo "   🔒 State is encrypted and secure"
echo "   🔄 State locking prevents concurrent modifications"
echo "   👥 Team collaboration with shared state"
echo "   💰 No Terraform Cloud account required!"
echo ""