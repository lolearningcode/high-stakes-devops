# S3 Backend Infrastructure
# This creates the S3 bucket and DynamoDB table for Terraform state management
# Run this FIRST before enabling the backend configuration

# Random suffix for bucket uniqueness
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# S3 bucket for Terraform state
resource "aws_s3_bucket" "terraform_state" {
  bucket = "cryptospins-terraform-state-${data.aws_caller_identity.current.account_id}"

  lifecycle {
    prevent_destroy = true
  }

  tags = merge(var.common_tags, {
    Name    = "CryptoSpins Terraform State"
    Purpose = "terraform-state-storage"
  })
}

# S3 bucket versioning
resource "aws_s3_bucket_versioning" "terraform_state_versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 bucket encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_encryption" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 bucket public access block
resource "aws_s3_bucket_public_access_block" "terraform_state_pab" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# DynamoDB table for state locking
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "cryptospins-terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  lifecycle {
    prevent_destroy = true
  }

  tags = merge(var.common_tags, {
    Name    = "CryptoSpins Terraform State Locks"
    Purpose = "terraform-state-locking"
  })
}

# Output the backend configuration for easy copy-paste
output "backend_configuration" {
  description = "Backend configuration to add to your terraform block"
  value       = <<EOF

Add this to your terraform block in backend.tf:

  backend "s3" {
    bucket         = "${aws_s3_bucket.terraform_state.id}"
    key            = "cryptospins/terraform.tfstate"
    region         = "${var.aws_region}"
    encrypt        = true
    dynamodb_table = "${aws_dynamodb_table.terraform_locks.name}"
  }

EOF
}
