locals {
  # Derive AZ names automatically
  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)

  # Create /20 per AZ for public and private (adjust if you want bigger)
  # 10.20.0.0/16 → split into /20 blocks per subnet tier.
  public_subnets  = [for i in range(var.az_count) : cidrsubnet(var.cidr_block, 4, i)]
  private_subnets = [for i in range(var.az_count) : cidrsubnet(var.cidr_block, 4, i + 8)]
}

data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = var.name
  cidr = var.cidr_block

  azs             = local.azs
  public_subnets  = local.public_subnets
  private_subnets = local.private_subnets

  enable_nat_gateway = true
  single_nat_gateway = var.single_nat_gateway

  enable_dns_hostnames = true
  enable_dns_support   = true

  # Tagging for cost/ownership
  tags = var.tags

  public_subnet_tags = merge(var.tags, {
    "kubernetes.io/role/elb" = "1"
  })

  private_subnet_tags = merge(var.tags, {
    "kubernetes.io/role/internal-elb" = "1"
  })
}