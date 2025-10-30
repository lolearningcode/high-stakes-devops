#!/bin/bash

# Import existing AWS resources into Terraform state
set -e

ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
BUCKET_NAME="cryptospins-terraform-state-${ACCOUNT_ID}"
TABLE_NAME="cryptospins-terraform-locks"
OIDC_PROVIDER_ARN="arn:aws:iam::${ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"
ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/github-actions-terraform-role"
POLICY_ARN="arn:aws:iam::${ACCOUNT_ID}:policy/github-actions-terraform-policy"

echo "🔄 Importing existing AWS resources into Terraform state..."
echo "Account ID: ${ACCOUNT_ID}"

cd terraform/

# Import OIDC Provider
echo "Importing OIDC Provider..."
terraform import aws_iam_openid_connect_provider.github_actions "${OIDC_PROVIDER_ARN}" || true

# Import S3 Bucket
echo "Importing S3 Bucket..."
terraform import aws_s3_bucket.terraform_state "${BUCKET_NAME}" || true

# Import S3 Bucket Versioning
echo "Importing S3 Bucket Versioning..."
terraform import aws_s3_bucket_versioning.terraform_state_versioning "${BUCKET_NAME}" || true

# Import S3 Bucket Server Side Encryption
echo "Importing S3 Bucket Encryption..."
terraform import aws_s3_bucket_server_side_encryption_configuration.terraform_state_encryption "${BUCKET_NAME}" || true

# Import S3 Bucket Public Access Block
echo "Importing S3 Bucket Public Access Block..."
terraform import aws_s3_bucket_public_access_block.terraform_state_pab "${BUCKET_NAME}" || true

# Import DynamoDB Table
echo "Importing DynamoDB Table..."
terraform import aws_dynamodb_table.terraform_locks "${TABLE_NAME}" || true

# Import IAM Role
echo "Importing IAM Role..."
terraform import aws_iam_role.github_actions "${ROLE_ARN##*/}" || true

# Import IAM Policy
echo "Importing IAM Policy..."
terraform import aws_iam_policy.terraform_policy "${POLICY_ARN}" || true

# Import IAM Role Policy Attachment
echo "Importing IAM Role Policy Attachment..."
terraform import aws_iam_role_policy_attachment.github_actions_terraform "github-actions-terraform-role/${POLICY_ARN}" || true

echo "✅ Import complete! Now running terraform plan to verify..."
terraform plan

echo "🎉 Resources successfully imported into Terraform state!"