# Kubecost Helm Release Configuration
# Provides real-time cost visibility for Kubernetes workloads

resource "helm_release" "kubecost" {
  count = var.enable_kubecost ? 1 : 0

  name             = "kubecost"
  repository       = "https://kubecost.github.io/cost-analyzer"
  chart            = "cost-analyzer"
  version          = var.kubecost_chart_version
  namespace        = "kubecost"
  create_namespace = true

  # Kubecost configuration values
  values = [
    templatefile("${path.module}/kubecost-values.yaml.tpl", {
      cluster_name          = local.cluster_name
      enable_spot_datacosts = var.enable_kubecost_spot_datacosts
      currency_code         = var.kubecost_currency_code
      aws_region            = var.aws_region
    })
  ]

  depends_on = [module.eks]

  # Wait for the deployment to be ready
  wait          = true
  wait_for_jobs = true
  timeout       = 600

  # Set resource limits to avoid overspending
  set {
    name  = "kubecostFrontend.resources.requests.cpu"
    value = "100m"
  }

  set {
    name  = "kubecostFrontend.resources.requests.memory"
    value = "256Mi"
  }

  set {
    name  = "kubecostFrontend.resources.limits.cpu"
    value = "500m"
  }

  set {
    name  = "kubecostFrontend.resources.limits.memory"
    value = "512Mi"
  }

  # Prometheus configuration
  set {
    name  = "prometheus.server.resources.requests.cpu"
    value = "200m"
  }

  set {
    name  = "prometheus.server.resources.requests.memory"
    value = "512Mi"
  }

  set {
    name  = "prometheus.server.resources.limits.cpu"
    value = "1000m"
  }

  set {
    name  = "prometheus.server.resources.limits.memory"
    value = "2Gi"
  }

  # Enable service monitor for existing Prometheus (if available)
  set {
    name  = "serviceMonitor.enabled"
    value = var.enable_prometheus_integration ? "true" : "false"
  }

  # AWS-specific configuration
  set {
    name  = "kubecostProductConfigs.awsRegion"
    value = var.aws_region
  }

  set {
    name  = "kubecostProductConfigs.clusterName"
    value = local.cluster_name
  }
}
