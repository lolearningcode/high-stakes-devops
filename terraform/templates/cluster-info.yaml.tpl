apiVersion: v1
kind: ConfigMap
metadata:
  name: cluster-info
  namespace: default
  labels:
    app: cryptospins-infrastructure
    managed-by: terraform
    cluster: ${cluster_name}
data:
  cluster_name: "${cluster_name}"
  cluster_region: "${cluster_region}"
  cluster_endpoint: "${cluster_endpoint}"
  oidc_issuer_url: "${oidc_issuer_url}"
  vpc_id: "${vpc_id}"
  private_subnets: "${private_subnets}"
  public_subnets: "${public_subnets}"
  
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-config
  namespace: default
  labels:
    app: cryptospins-infrastructure
    managed-by: terraform
data:
  AWS_REGION: "${cluster_region}"
  AWS_DEFAULT_REGION: "${cluster_region}"
  CLUSTER_NAME: "${cluster_name}"