#!/bin/bash
set -o xtrace

# Bootstrap the node to join the EKS cluster
/etc/eks/bootstrap.sh ${cluster_name} ${bootstrap_arguments} \
  --b64-cluster-ca ${cluster_ca_data} \
  --apiserver-endpoint ${cluster_endpoint}

# Configure kubelet for better resource management
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
sysctl -p

# Install additional packages for monitoring
yum update -y
yum install -y htop iotop

# Configure log rotation for container logs
cat > /etc/logrotate.d/docker-containers << EOF
/var/lib/docker/containers/*/*.log {
    rotate 7
    daily
    compress
    size=1M
    missingok
    delaycompress
    copytruncate
}
EOF