# Kubecost configuration values
global:
  # AWS-specific configuration
  aws:
    region: ${aws_region}
  
  # Currency settings
  currencyCode: ${currency_code}
  
  # Cluster identification
  cluster:
    name: ${cluster_name}

# Kubecost frontend configuration
kubecostFrontend:
  # Resource limits for cost control
  resources:
    requests:
      cpu: 100m
      memory: 256Mi
    limits:
      cpu: 500m
      memory: 512Mi

# Cost model configuration  
kubecostModel:
  # Enable spot instance cost tracking
  spotDataFeed: ${enable_spot_datacosts}
  
  # AWS integration
  awsRegion: ${aws_region}
  
  # Resource limits
  resources:
    requests:
      cpu: 200m
      memory: 256Mi
    limits:
      cpu: 800m
      memory: 2Gi

# Prometheus configuration (lightweight setup)
prometheus:
  server:
    # Resource limits for Prometheus
    resources:
      requests:
        cpu: 200m
        memory: 512Mi
      limits:
        cpu: 1000m
        memory: 2Gi
    
    # Retention settings
    retention: "7d"
    
    # Storage size
    persistentVolume:
      size: 8Gi
      storageClass: "gp3"
    
    # Scrape configuration for cost metrics
    scrapeInterval: 60s
    evaluationInterval: 60s

  # Disable alertmanager to save resources
  alertmanager:
    enabled: false
  
  # Disable pushgateway to save resources  
  pushgateway:
    enabled: false

# Network policy (optional security)
networkPolicy:
  enabled: false

# Service account configuration
serviceAccount:
  create: true
  name: kubecost

# Ingress configuration (disabled by default)
ingress:
  enabled: false
  className: "nginx"
  annotations:
    nginx.ingress.kubernetes.io/auth-type: basic
    nginx.ingress.kubernetes.io/auth-secret: kubecost-auth
  hosts:
    - host: kubecost.${cluster_name}.local
      paths:
        - path: /
          pathType: Prefix

# Node selector for cost-optimized placement
nodeSelector: {}

# Tolerations for spot instances
tolerations: []

# Affinity rules
affinity: {}

# Additional labels
podLabels:
  app: kubecost
  cost-monitoring: enabled

# Security context
securityContext:
  runAsNonRoot: true
  runAsUser: 1001
  fsGroup: 1001