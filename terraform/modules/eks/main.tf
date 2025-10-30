# EKS Module - Main Configuration
locals {
  cluster_name = var.cluster_name

  # Common tags for all EKS resources
  common_tags = merge(var.tags, {
    "kubernetes.io/cluster/${local.cluster_name}" = "owned"
  })
}

# EKS Cluster
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = local.cluster_name
  cluster_version = var.cluster_version

  # Network configuration
  vpc_id                   = var.vpc_id
  subnet_ids               = var.subnet_ids
  control_plane_subnet_ids = var.control_plane_subnet_ids

  # Cluster endpoint configuration
  cluster_endpoint_public_access       = var.cluster_endpoint_public_access
  cluster_endpoint_private_access      = var.cluster_endpoint_private_access
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs

  # Cluster addons
  cluster_addons = var.cluster_addons

  # Node groups
  eks_managed_node_groups = var.eks_managed_node_groups

  # Fargate profiles
  fargate_profiles = var.fargate_profiles

  # Enable IRSA (IAM Roles for Service Accounts)
  enable_irsa = var.enable_irsa

  # Cluster encryption
  cluster_encryption_config = var.cluster_encryption_config

  # Logging
  cluster_enabled_log_types = var.cluster_enabled_log_types

  # Tags
  tags = local.common_tags

  cluster_tags = {
    Name = local.cluster_name
  }
}

# IAM role for EBS CSI driver
data "aws_iam_policy_document" "ebs_csi_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }

    principals {
      identifiers = [module.eks.oidc_provider_arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "ebs_csi_role" {
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_assume_role.json
  name               = "${local.cluster_name}-ebs-csi-role"

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "ebs_csi_policy" {
  role       = aws_iam_role.ebs_csi_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

# Karpenter configuration
# Add Karpenter as an EKS addon (available in EKS 1.23+)
resource "aws_eks_addon" "karpenter" {
  count = var.enable_karpenter ? 1 : 0

  cluster_name                = module.eks.cluster_name
  addon_name                  = "eks-pod-identity-agent"
  addon_version               = var.karpenter_addon_version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [module.eks]

  tags = local.common_tags
}

# Create Launch Template for Karpenter nodes
resource "aws_launch_template" "karpenter_nodes" {
  count = var.enable_karpenter ? 1 : 0

  name_prefix = "${local.cluster_name}-karpenter-"
  description = "Launch template for Karpenter managed nodes"

  vpc_security_group_ids = [module.eks.node_security_group_id]

  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    cluster_name        = local.cluster_name
    cluster_endpoint    = module.eks.cluster_endpoint
    cluster_ca_data     = module.eks.cluster_certificate_authority_data
    bootstrap_arguments = ""
  }))

  monitoring {
    enabled = true
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = var.karpenter_node_disk_size
      volume_type           = "gp3"
      iops                  = 3000
      throughput            = 125
      encrypted             = true
      delete_on_termination = true
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(local.common_tags, {
      Name                   = "${local.cluster_name}-karpenter-node"
      "karpenter.sh/cluster" = local.cluster_name
    })
  }

  tags = local.common_tags
}
