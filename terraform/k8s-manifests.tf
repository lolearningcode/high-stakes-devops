# Generate Kubernetes manifests based on Terraform outputs
# These will be consumed by ArgoCD for GitOps deployment

# Generate cluster info ConfigMap
resource "local_file" "cluster_info_configmap" {
  filename = "${path.module}/k8s-manifests/cluster-info.yaml"

  content = templatefile("${path.module}/templates/cluster-info.yaml.tpl", {
    cluster_name     = module.eks.cluster_name
    cluster_endpoint = module.eks.cluster_endpoint
    cluster_region   = var.aws_region
    oidc_issuer_url  = module.eks.cluster_oidc_issuer_url
    vpc_id           = module.vpc.vpc_id
    private_subnets  = join(",", module.vpc.private_subnet_ids)
    public_subnets   = join(",", module.vpc.public_subnet_ids)
  })

  depends_on = [module.eks, module.vpc]
}

# Generate service account for applications needing AWS access
resource "local_file" "app_service_account" {
  filename = "${path.module}/k8s-manifests/app-service-account.yaml"

  content = templatefile("${path.module}/templates/service-account.yaml.tpl", {
    cluster_name      = module.eks.cluster_name
    oidc_provider_arn = module.eks.oidc_provider_arn
    namespace         = "default"
    service_account   = "cryptospins-api-sa"
  })

  depends_on = [module.eks]
}

# Generate external-dns configuration if needed
resource "local_file" "external_dns_config" {
  filename = "${path.module}/k8s-manifests/external-dns-config.yaml"

  content = templatefile("${path.module}/templates/external-dns.yaml.tpl", {
    cluster_name = module.eks.cluster_name
    aws_region   = var.aws_region
    domain_name  = "cryptospins.local" # Default domain for local development
  })

  depends_on = [module.eks]
}

# Commit generated manifests to git (for ArgoCD to pick up)
resource "null_resource" "commit_manifests" {
  triggers = {
    cluster_info    = local_file.cluster_info_configmap.content
    service_account = local_file.app_service_account.content
  }

  provisioner "local-exec" {
    command = <<-EOT
      cd ${path.module}
      git add k8s-manifests/
      git diff --cached --exit-code || {
        git commit -m "chore: update generated k8s manifests [skip ci]"
        echo "📝 Generated manifests committed to git"
      }
    EOT
  }

  depends_on = [
    local_file.cluster_info_configmap,
    local_file.app_service_account,
    local_file.external_dns_config
  ]
}
