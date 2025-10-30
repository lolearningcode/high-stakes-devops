apiVersion: karpenter.sh/v1beta1
kind: NodePool
metadata:
  name: default-nodepool
  labels:
    managed-by: terraform
    cluster: ${cluster_name}
spec:
  # Template for nodes
  template:
    metadata:
      labels:
        managed-by: terraform
        cluster: ${cluster_name}
      annotations:
        karpenter.sh/cluster: ${cluster_name}
    
    spec:
      # NodeClass reference
      nodeClassRef:
        apiVersion: karpenter.k8s.aws/v1beta1
        kind: EC2NodeClass
        name: default-nodeclass
      
      # Resource requirements
      requirements:
        - key: karpenter.sh/capacity-type
          operator: In
          values: ["spot", "on-demand"]
        - key: kubernetes.io/arch
          operator: In
          values: ["amd64"]
        - key: node.kubernetes.io/instance-type
          operator: In
          values: 
            - m5.large
            - m5.xlarge  
            - m5.2xlarge
            - m5.4xlarge
            - c5.large
            - c5.xlarge
            - c5.2xlarge
            - c5.4xlarge
            - r5.large
            - r5.xlarge
            - r5.2xlarge
      
      # Taints (optional)
      taints:
        - key: karpenter.sh/default
          value: "true"
          effect: NoSchedule

  # Disruption settings - when to replace nodes
  disruption:
    # Consolidation policy
    consolidationPolicy: WhenUnderutilized
    consolidateAfter: 30s
    
    # Node expiration
    expireAfter: 2160h # 90 days

  # Scaling limits
  limits:
    cpu: 1000
    memory: 1000Gi