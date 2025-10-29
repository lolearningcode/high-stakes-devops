# High Stakes DevOps 🎰☁️

A comprehensive cloud-native DevOps implementation featuring a crypto-gaming API, complete with Infrastructure as Code, GitOps, monitoring, and CI/CD pipelines.

## 🏗️ Architecture Overview

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   GitHub Repo   │───▶│  GitHub Actions  │───▶│   Amazon ECR    │
│   (GitOps)      │    │   (CI/CD)        │    │ (Container Reg) │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│     ArgoCD      │◀───│   Terraform     │───▶│      EKS        │
│   (GitOps)      │    │    (IaC)        │    │   Cluster       │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│  CryptoSpins    │    │   Prometheus     │    │     Grafana     │
│     API         │    │  (Metrics)       │    │  (Dashboards)   │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

## 🎯 Project Components

### 🎰 **CryptoSpins API** (`api/`)
High-performance crypto gaming backend built with FastAPI:
- **Gaming Endpoints**: `/bet`, `/balance`, `/stats`  
- **30% Win Rate**: Configurable probability mechanics
- **Prometheus Metrics**: Built-in observability
- **Auto-scaling**: HPA with 2-10 replicas
- **Security**: Non-root containers, health checks

### 🏗️ **Infrastructure** (`terraform/`)
Production-grade AWS infrastructure using Terraform:
- **EKS Cluster**: Kubernetes 1.28 with managed node groups
- **VPC Setup**: Multi-AZ with private/public subnets
- **IAM/RBAC**: Secure access with EKS Access Entries
- **Storage**: EBS CSI driver for persistent volumes
- **Load Balancing**: AWS Load Balancer Controller

### 🔄 **GitOps** (`argo/`)
Automated deployment with ArgoCD:
- **App-of-Apps Pattern**: Hierarchical application management
- **Auto-sync**: Continuous deployment from Git
- **Self-healing**: Automatic drift correction
- **Monitoring Stack**: Prometheus + Grafana deployment

### 📊 **Observability** (`observability/`)
Comprehensive monitoring and alerting:
- **Prometheus**: Metrics collection and storage
- **Grafana**: Custom dashboards and visualization
- **Gaming Metrics**: Real-time betting statistics
- **Infrastructure Monitoring**: Cluster and application health

## 🚀 Quick Start

### Prerequisites
```bash
# Required tools
aws-cli >= 2.0
terraform >= 1.6
kubectl >= 1.28
docker >= 20.0
```

### 1. Deploy Infrastructure
```bash
cd terraform/
terraform init
terraform plan -out=eks.plan
terraform apply eks.plan
```

### 2. Configure kubectl
```bash
aws eks update-kubeconfig --region us-east-1 --name high-stakes-devops-eks
kubectl get nodes
```

### 3. Deploy ArgoCD
```bash
kubectl create namespace argocd
helm install argocd argo/argo-cd -n argocd
```

### 4. Build & Deploy API
```bash
cd api/
./build-and-push.sh
kubectl apply -f ../argo/
```

## 🧪 Testing

### Run Unit Tests
```bash
cd api/
./run-tests.sh
```

### Test Coverage
- **31 Test Cases**: Complete API and business logic coverage
- **Mocking**: Controlled probability testing
- **Edge Cases**: Boundary conditions and error handling
- **CI/CD**: Automated testing on every commit

### Development Workflow
```bash
# Install dependencies
make install

# Run tests in watch mode  
make test-watch

# Run API locally
make run

# Docker testing
make docker-test
```

## 📈 Monitoring & Metrics

### CryptoSpins Gaming Metrics
- `cryptospins_total_bets` - Total bets placed
- `cryptospins_win_rate` - Current win percentage  
- `cryptospins_total_wagered` - Total amount wagered
- `cryptospins_house_edge` - House edge percentage
- `cryptospins_active_users` - Active user count

### Infrastructure Metrics
- EKS cluster health and resource utilization
- Pod CPU/memory usage and scaling events
- Network traffic and load balancer performance

## 🔧 Configuration

### Environment Variables
| Variable | Description | Default |
|----------|-------------|---------|
| `LOG_LEVEL` | Application log level | `INFO` |
| `ENV` | Environment (dev/staging/prod) | `production` |

### Resource Limits
```yaml
# API Pods
requests:
  memory: 128Mi
  cpu: 100m
limits:
  memory: 512Mi  
  cpu: 500m
```

## 🔐 Security

### Best Practices Implemented
- ✅ Non-root containers with security contexts
- ✅ Resource limits and network policies
- ✅ IAM least-privilege access
- ✅ Secrets management with Kubernetes secrets
- ✅ Image vulnerability scanning

### AWS IAM Roles
- **EKS Cluster Role**: Manages cluster lifecycle
- **Node Group Role**: EC2 instance permissions
- **EBS CSI Role**: Storage provisioning access

## 🚢 CI/CD Pipeline

### GitHub Actions Workflow
```yaml
Trigger: Push to main/develop, Pull Requests
├── Test Phase
│   ├── Python 3.11 unit tests
│   ├── Code linting (flake8)
│   └── Coverage reporting
└── Build & Deploy Phase (main only)
    ├── Docker build (AMD64)
    ├── ECR push
    └── Kubernetes manifest update
```

### Setup Instructions
1. Add AWS credentials to GitHub secrets:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`  
2. See [GitHub Actions AWS Setup](docs/github-actions-aws-setup.md)

## 📁 Project Structure

```
high-stakes-devops/
├── api/                          # CryptoSpins API
│   ├── app/
│   │   ├── main.py              # FastAPI application
│   │   └── requirements.txt      # Production dependencies
│   ├── tests/                   # Unit test suite
│   ├── k8s/                     # Kubernetes manifests
│   ├── Dockerfile               # Container definition
│   └── build-and-push.sh        # Build automation
├── terraform/                   # Infrastructure as Code
│   ├── main.tf                  # Root configuration
│   ├── modules/
│   │   ├── vpc/                # VPC module
│   │   └── eks/                # EKS module
│   └── *.tf                    # Variables, outputs
├── argo/                       # GitOps applications
│   ├── app-of-apps.yaml        # Root ArgoCD app
│   └── *-app.yaml              # Child applications
├── observability/              # Monitoring configuration
│   ├── prometheus-values.yaml
│   ├── grafana-values.yaml
│   └── dashboards/
└── docs/                       # Documentation
```

## 🎮 API Usage Examples

### Place a Bet
```bash
curl -X POST https://api-url/bet \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "player123",
    "amount": 100.0,
    "game_type": "slots",
    "multiplier": 2.0
  }'
```

### Check Balance  
```bash
curl https://api-url/balance/player123
```

### View Statistics
```bash
curl https://api-url/stats
```

## 🤝 Contributing

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Test** your changes (`make test`)
4. **Commit** your changes (`git commit -m 'Add amazing feature'`)
5. **Push** to the branch (`git push origin feature/amazing-feature`)
6. **Open** a Pull Request

## 📋 Roadmap

- [ ] **Phase 5**: Advanced monitoring dashboards
- [ ] **Phase 6**: Multi-region deployment
- [ ] **Phase 7**: Chaos engineering and resilience testing
- [ ] **Phase 8**: Advanced security scanning and compliance

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🏆 Achievements

- ✅ **Production-ready** Kubernetes infrastructure
- ✅ **100%** test coverage on critical business logic  
- ✅ **GitOps** continuous deployment
- ✅ **Security** hardened containers and IAM
- ✅ **Observability** comprehensive metrics and monitoring
- ✅ **CI/CD** automated testing and deployment

---

**Built with ❤️ for high-stakes DevOps challenges** 🎰