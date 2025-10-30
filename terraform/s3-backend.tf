# S3 Backend Infrastructure
# This creates the S3 bucket and DynamoDB table for Terraform state management
# Run this FIRST before enabling the backend configuration

# Random suffix for bucket uniqueness
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# S3 bucket for Terraform state (use existing one)
data "aws_s3_bucket" "terraform_state" {
  bucket = "cryptospins-terraform-state-${data.aws_caller_identity.current.account_id}"
}

# S3 bucket configurations (managed by setup script)
# These are already configured by the setup-github-oidc.sh script

# DynamoDB table for state locking (use existing one)
data "aws_dynamodb_table" "terraform_locks" {
  name = "cryptospins-terraform-locks"
}

# Output the backend configuration for easy copy-paste
output "backend_configuration" {
  description = "Backend configuration to add to your terraform block"
  value       = <<EOF

Add this to your terraform block in backend.tf:

  backend "s3" {
    bucket         = "${data.aws_s3_bucket.terraform_state.id}"
    key            = "cryptospins/terraform.tfstate"
    region         = "${var.aws_region}"
    encrypt        = true
    dynamodb_table = "${data.aws_dynamodb_table.terraform_locks.name}"
  }
EOF
}
