# Karpenter NodeClass and NodePool configurations
# These define how Karpenter should provision nodes

# Create a directory for Karpenter manifests
resource "local_file" "karpenter_nodeclass" {
  count = var.enable_karpenter ? 1 : 0

  content = templatefile("${path.module}/karpenter-nodeclass.yaml.tpl", {
    cluster_name          = local.cluster_name
    instance_profile_name = "${local.cluster_name}-karpenter-node-instance-profile"
    security_group_ids    = [module.eks.node_security_group_id]
    subnet_ids            = var.subnet_ids
    cluster_ca_data       = module.eks.cluster_certificate_authority_data
    cluster_endpoint      = module.eks.cluster_endpoint
  })

  filename = "${path.root}/k8s-manifests/karpenter-nodeclass.yaml"
}

resource "local_file" "karpenter_nodepool" {
  count = var.enable_karpenter ? 1 : 0

  content = templatefile("${path.module}/karpenter-nodepool.yaml.tpl", {
    cluster_name = local.cluster_name
  })

  filename = "${path.root}/k8s-manifests/karpenter-nodepool.yaml"
}
