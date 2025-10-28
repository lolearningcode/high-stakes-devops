# CryptoSpins API 🎰💰

A high-stakes crypto-gaming backend API built with FastAPI, where crypto meets spinning action for the ultimate gaming experience.

## 🎯 Features

- **Health Monitoring**: `/health` endpoint for Kubernetes probes
- **User Balance Management**: Track and manage user crypto balances
- **Betting System**: Place bets with configurable multipliers
- **Game Statistics**: Real-time gaming metrics and analytics
- **Prometheus Metrics**: Built-in metrics endpoint for observability
- **High Availability**: Auto-scaling with HPA support

## 🚀 API Endpoints

### Core Endpoints
- `GET /` - Welcome message
- `GET /health` - Health check for monitoring
- `GET /balance/{user_id}` - Get user balance
- `POST /bet` - Place a bet
- `GET /bet/{bet_id}` - Get bet details
- `GET /stats` - Overall gaming statistics
- `GET /metrics` - Prometheus metrics

### Example Usage

#### Check Balance
```bash
curl http://localhost:8000/balance/user123
```

#### Place a Bet
```bash
curl -X POST http://localhost:8000/bet \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "user123",
    "amount": 100.0,
    "game_type": "slots",
    "multiplier": 2.0
  }'
```

#### Get Statistics
```bash
curl http://localhost:8000/stats
```

## 🏗️ Development

### Local Development
```bash
# Install dependencies
pip install -r app/requirements.txt

# Run the API
cd app/
python main.py
```

### Docker Build
```bash
# Build the image
docker build -t cryptospins-api .

# Run locally
docker run -p 8000:8000 cryptospins-api
```

## ☁️ Deployment

### ECR Setup
```bash
# Create ECR repository
aws ecr create-repository --repository-name cryptospins-api --region us-east-1

# Get login token
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin 269599744150.dkr.ecr.us-east-1.amazonaws.com

# Tag and push
docker tag cryptospins-api:latest 269599744150.dkr.ecr.us-east-1.amazonaws.com/cryptospins-api:latest
docker push 269599744150.dkr.ecr.us-east-1.amazonaws.com/cryptospins-api:latest
```

### Kubernetes Deployment
```bash
# Apply manifests
kubectl apply -f k8s/

# Check deployment
kubectl get pods -l app=cryptospins-api
kubectl get svc cryptospins-api
```

### ArgoCD GitOps
The API is deployed using ArgoCD for GitOps-based continuous deployment. See `../argo/cryptospins-app.yaml` for the ArgoCD application definition.

## 📊 Monitoring

The API exposes metrics at `/metrics` endpoint compatible with Prometheus:
- `cryptospins_total_bets` - Total number of bets placed
- `cryptospins_total_wins` - Total winning bets
- `cryptospins_win_rate` - Win rate percentage
- `cryptospins_total_wagered` - Total amount wagered
- `cryptospins_house_edge` - House edge percentage
- `cryptospins_active_users` - Number of active users

## 🔧 Configuration

### Environment Variables
- `ENV` - Environment (development/production)
- `LOG_LEVEL` - Logging level (INFO/DEBUG/WARNING/ERROR)

### Resource Limits
- **Requests**: 128Mi memory, 100m CPU
- **Limits**: 512Mi memory, 500m CPU
- **Auto-scaling**: 2-10 replicas based on CPU (70%) and memory (80%) usage

## 🎲 Game Logic

- **Win Rate**: 30% (high-stakes gaming!)
- **Default Multiplier**: 2.0x
- **Starting Balance**: 1000.0 for new users
- **Supported Games**: Slots (extensible for more games)

## 🛡️ Security

- Runs as non-root user (UID 1000)
- Resource limits enforced
- Health checks for reliability
- Immutable deployment patterns

## 📈 Scaling

The API supports horizontal auto-scaling based on:
- CPU utilization (target: 70%)
- Memory utilization (target: 80%)
- Min replicas: 2
- Max replicas: 10

Scale-down is conservative (10% every 60s) while scale-up is aggressive (50% every 30s) to handle traffic spikes in gaming workloads.