# EKS Module Variables
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
  default     = "1.28"
}

# Network Configuration
variable "vpc_id" {
  description = "ID of the VPC where the cluster will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the EKS cluster"
  type        = list(string)
}

variable "control_plane_subnet_ids" {
  description = "List of subnet IDs for the EKS cluster control plane. Defaults to subnet_ids if not specified"
  type        = list(string)
  default     = []
}

# Cluster Endpoint Configuration
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

# Cluster Addons
variable "cluster_addons" {
  description = "Map of cluster addon configurations to enable for the cluster"
  type = map(object({
    addon_version            = optional(string)
    resolve_conflicts        = optional(string)
    service_account_role_arn = optional(string)
  }))
  default = {
    coredns = {
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {
      resolve_conflicts = "OVERWRITE"
    }
    vpc-cni = {
      resolve_conflicts = "OVERWRITE"
    }
    aws-ebs-csi-driver = {
      resolve_conflicts = "OVERWRITE"
      addon_version     = "v1.30.0-eksbuild.1"
    }
  }
}

# Node Groups
variable "eks_managed_node_groups" {
  description = "Map of EKS managed node group definitions"
  type        = any
  default     = {}
}

# Fargate Profiles
variable "fargate_profiles" {
  description = "Map of Fargate profile definitions"
  type        = any
  default     = {}
}

# IRSA (IAM Roles for Service Accounts)
variable "enable_irsa" {
  description = "Whether to create an OpenID Connect Provider for EKS to enable IRSA"
  type        = bool
  default     = true
}

# Cluster Encryption
variable "cluster_encryption_config" {
  description = "Configuration block with encryption configuration for the cluster"
  type = list(object({
    provider_key_arn = string
    resources        = list(string)
  }))
  default = []
}

# Authentication and Authorization
variable "manage_aws_auth_configmap" {
  description = "Whether to manage the aws-auth configmap"
  type        = bool
  default     = true
}

variable "aws_auth_roles" {
  description = "List of role maps to add to the aws-auth configmap"
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))
  default = []
}

variable "aws_auth_users" {
  description = "List of user maps to add to the aws-auth configmap"
  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))
  default = []
}

variable "aws_auth_accounts" {
  description = "List of account maps to add to the aws-auth configmap"
  type        = list(string)
  default     = []
}

# Logging
variable "cluster_enabled_log_types" {
  description = "List of control plane logging to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

# Tags
variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

# Karpenter Configuration
variable "enable_karpenter" {
  description = "Enable Karpenter for cluster auto-scaling"
  type        = bool
  default     = false
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
  description = "Enable Kubecost for cost monitoring"
  type        = bool
  default     = false
}

variable "kubecost_chart_version" {
  description = "Version of the Kubecost Helm chart"
  type        = string
  default     = "1.108.1"
}

variable "enable_kubecost_spot_datacosts" {
  description = "Enable spot instance cost data in Kubecost"
  type        = bool
  default     = true
}

variable "kubecost_currency_code" {
  description = "Currency code for cost display in Kubecost"
  type        = string
  default     = "USD"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "enable_prometheus_integration" {
  description = "Enable Prometheus integration for Kubecost"
  type        = bool
  default     = true
}

