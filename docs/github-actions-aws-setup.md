# GitHub Actions AWS Setup

This document explains how to configure AWS credentials for GitHub Actions to enable automatic Docker image builds and ECR pushes.

## 🔐 Setting Up AWS Credentials

### Step 1: Create AWS IAM User

1. **Go to AWS IAM Console**
   - Navigate to [IAM Users](https://console.aws.amazon.com/iam/home#/users)
   - Click "Add users"

2. **Create User**
   - User name: `github-actions-cryptospins`
   - Access type: ✅ Programmatic access
   - Click "Next: Permissions"

3. **Set Permissions**
   - Attach existing policies directly:
     - ✅ `AmazonEC2ContainerRegistryFullAccess`
     - ✅ `AmazonEKSWorkerNodePolicy` (if updating K8s deployments)
   - Click "Next: Tags" → "Next: Review" → "Create user"

4. **Save Credentials**
   - **Access Key ID**: Copy this value
   - **Secret Access Key**: Copy this value (shown only once!)

### Step 2: Configure GitHub Repository Secrets

1. **Go to Repository Settings**
   - Navigate to your GitHub repository
   - Click **Settings** → **Secrets and variables** → **Actions**

2. **Add Repository Secrets**
   - Click **New repository secret**
   - Add these secrets:

   | Name | Value |
   |------|-------|
   | `AWS_ACCESS_KEY_ID` | Your IAM user access key ID |
   | `AWS_SECRET_ACCESS_KEY` | Your IAM user secret access key |

### Step 3: Verify Setup

Once credentials are added, the GitHub Actions workflow will:
- ✅ Run tests on every push/PR
- ✅ Build Docker images for AMD64 architecture  
- ✅ Push images to ECR on successful main branch builds
- ✅ Update Kubernetes deployment files automatically

## 🔧 Manual ECR Operations

If you need to manually push images before setting up GitHub Actions:

```bash
# Login to ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin 269599744150.dkr.ecr.us-east-1.amazonaws.com

# Build and push
cd api/
./build-and-push.sh
```

## 🚫 Security Best Practices

### ✅ DO:
- Use dedicated IAM user with minimal permissions
- Rotate credentials regularly
- Monitor CloudTrail logs for unusual activity
- Use repository secrets (never commit credentials)

### ❌ DON'T:
- Use personal AWS credentials
- Grant excessive permissions
- Commit credentials to git
- Share credentials in plain text

## 🔍 Troubleshooting

### Common Issues:

**"Credentials could not be loaded"**
- Verify secrets are named exactly: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`
- Check IAM user has programmatic access enabled
- Ensure ECR permissions are attached

**"Access Denied" when pushing to ECR**
- Verify IAM user has `AmazonEC2ContainerRegistryFullAccess`
- Check ECR repository exists: `aws ecr describe-repositories --repository-names cryptospins-api`

**Docker build fails**
- Ensure `--platform linux/amd64` is used for EKS compatibility
- Check Dockerfile syntax and dependencies

## 📊 Monitoring

Monitor your CI/CD pipeline:
- **GitHub Actions**: Check workflow runs in repository Actions tab
- **AWS CloudTrail**: Monitor API calls and access patterns
- **ECR Console**: Verify image pushes and repository status

## 🔄 Workflow Behavior

| Trigger | Action | Result |
|---------|--------|---------|
| Push to `main` | Full test + build + deploy | New image in ECR + updated K8s manifests |
| Pull Request | Tests only | Validate changes before merge |
| Push to other branches | Tests only | Quality assurance |

The workflow is designed to gracefully handle missing AWS credentials during development while providing full CI/CD capabilities in production.