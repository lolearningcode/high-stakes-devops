# AWS Region
variable "aws_region" {
  description = "The AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

# VPC Configuration
variable "vpc_name" {
  description = "Name for the VPC"
  type        = string
  default     = "high-stakes-devops-vpc"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.20.0.0/16"
}

variable "az_count" {
  description = "Number of availability zones to use"
  type        = number
  default     = 3
}

variable "single_nat_gateway" {
  description = "Whether to use a single NAT gateway for all private subnets"
  type        = bool
  default     = false
}

# EKS Configuration
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "high-stakes-devops-eks"
}

variable "cluster_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
  default     = "1.28"
}

variable "cluster_endpoint_public_access" {
  description = "Whether the Amazon EKS public API server endpoint is enabled"
  type        = bool
  default     = true
}

variable "cluster_endpoint_private_access" {
  description = "Whether the Amazon EKS private API server endpoint is enabled"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks that can access the Amazon EKS public API server endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enable_irsa" {
  description = "Whether to create an OpenID Connect Provider for EKS to enable IRSA"
  type        = bool
  default     = true
}

variable "manage_aws_auth_configmap" {
  description = "Whether to manage the aws-auth configmap"
  type        = bool
  default     = true
}

variable "aws_auth_users" {
  description = "List of user maps to add to the aws-auth configmap"
  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))
  default = [
    {
      userarn  = "arn:aws:iam::269599744150:user/itadmin-terraform"
      username = "itadmin-terraform"
      groups   = ["system:masters"]
    }
  ]
}

variable "eks_managed_node_groups" {
  description = "Map of EKS managed node group definitions"
  type        = any
  default = {
    main = {
      name = "main-node-group"

      instance_types = ["t3.medium"]

      min_size     = 1
      max_size     = 3
      desired_size = 2

      disk_size = 20

      labels = {
        Environment = "dev"
        NodeGroup   = "main"
      }

      taints = []

      update_config = {
        max_unavailable_percentage = 25
      }

      tags = {
        Environment = "dev"
      }
    }
  }
}

# Common tags for resources
variable "common_tags" {
  description = "Common tags to be applied to all resources"
  type        = map(string)
  default = {
    Environment = "dev"
    Project     = "high-stakes-devops"
    ManagedBy   = "terraform"
  }
}

# Karpenter Configuration
variable "enable_karpenter" {
  description = "Enable Karpenter for intelligent auto-scaling"
  type        = bool
  default     = true
}

variable "karpenter_addon_version" {
  description = "Version of the Karpenter EKS addon"
  type        = string
  default     = "v0.37.0-eksbuild.2"
}

variable "karpenter_node_disk_size" {
  description = "Disk size in GB for Karpenter managed nodes"
  type        = number
  default     = 100
}

# Kubecost Configuration
variable "enable_kubecost" {
  description = "Enable Kubecost for cost monitoring and optimization"
  type        = bool
  default     = true
}

variable "kubecost_chart_version" {
  description = "Version of the Kubecost Helm chart"
  type        = string
  default     = "1.108.1"
}

variable "enable_kubecost_spot_datacosts" {
  description = "Enable spot instance cost data tracking in Kubecost"
  type        = bool
  default     = true
}

variable "kubecost_currency_code" {
  description = "Currency code for cost display (USD, EUR, etc.)"
  type        = string
  default     = "USD"
}

variable "enable_prometheus_integration" {
  description = "Enable Prometheus integration with existing monitoring stack"
  type        = bool
  default     = true
}
