apiVersion: karpenter.k8s.aws/v1beta1
kind: EC2NodeClass
metadata:
  name: default-nodeclass
  labels:
    managed-by: terraform
    cluster: ${cluster_name}
spec:
  # AMI family for the nodes
  amiFamily: AL2
  
  # Instance profile for Karpenter nodes
  instanceProfile: ${instance_profile_name}
  
  # Subnets where nodes can be launched
  subnetSelectorTerms:
    %{ for subnet_id in subnet_ids ~}
    - id: ${subnet_id}
    %{ endfor ~}
  
  # Security groups for nodes
  securityGroupSelectorTerms:
    %{ for sg_id in security_group_ids ~}
    - id: ${sg_id}
    %{ endfor ~}
  
  # User data for node initialization
  userData: |
    #!/bin/bash
    /etc/eks/bootstrap.sh ${cluster_name} \
      --b64-cluster-ca ${cluster_ca_data} \
      --apiserver-endpoint ${cluster_endpoint}
  
  # Instance types to exclude (expensive ones)
  requirements:
    - key: karpenter.sh/capacity-type
      operator: In
      values: ["spot", "on-demand"]
    - key: kubernetes.io/arch
      operator: In
      values: ["amd64"]
    - key: node.kubernetes.io/instance-type
      operator: NotIn
      values: 
        - m5.24xlarge
        - m5.12xlarge
        - c5.24xlarge
        - c5.12xlarge
        - r5.24xlarge
        - r5.12xlarge
  
  # Tags for instances
  tags:
    managed-by: terraform
    cluster: ${cluster_name}
    karpenter.sh/cluster: ${cluster_name}
    
  # Block device mappings
  blockDeviceMappings:
    - deviceName: /dev/xvda
      ebs:
        volumeSize: 100Gi
        volumeType: gp3
        iops: 3000
        throughput: 125
        encrypted: true
        deleteOnTermination: true