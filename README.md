# Simple Redis App for Kubernetes

A simple Kubernetes-native application with a backend that connects to Redis and a frontend to display and manage data.

## Architecture

- **Frontend**: Simple web UI with buttons to add sample data and view Redis contents
- **Backend**: Node.js/Express API that connects to Redis
- **Redis**: In-cluster Redis instance (or connect to external Redis)

## Prerequisites

- Kubernetes cluster (minikube, kind, or any K8s cluster)
- kubectl configured to access your cluster
- Docker (for building images)

## Quick Start

### One-Line Install from GitHub

**With in-cluster Redis:**
```bash
curl -fsSL https://raw.githubusercontent.com/ryandockman/simple-redis-app/main/install.sh | bash
```

**With external Redis endpoint:**
```bash
curl -fsSL https://raw.githubusercontent.com/ryandockman/simple-redis-app/main/install.sh | bash -s -- --redis-endpoint 10.0.0.5:6379
```

**Uninstall:**
```bash
curl -fsSL https://raw.githubusercontent.com/ryandockman/simple-redis-app/main/install.sh | bash -s -- --cleanup
```

### Local Installation

Clone the repository and deploy:

```bash
git clone https://github.com/ryandockman/simple-redis-app.git
cd simple-redis-app

# Deploy with in-cluster Redis
./deploy.sh

# OR deploy with external Redis
./deploy.sh --redis-endpoint 10.0.0.5:6379
```

### Access the Application

After deployment, access the frontend:

```bash
kubectl port-forward -n redis-app svc/frontend 8080:80
```

Then open http://localhost:8080 in your browser.

### Cleanup

To remove all resources:

```bash
./cleanup.sh
```

## Configuration

### Using External Redis

You can connect to an external Redis instance by passing the `--redis-endpoint` flag:

```bash
./deploy.sh --redis-endpoint <host>:<port>
```

Examples:
```bash
# External Redis at IP 10.0.0.5 on port 6379
./deploy.sh --redis-endpoint 10.0.0.5:6379

# External Redis at custom port
./deploy.sh --redis-endpoint redis.example.com:6380
```

### Using In-Cluster Redis

If you don't specify a Redis endpoint, the app will deploy its own Redis instance in the cluster:

```bash
./deploy.sh
```

### Updating Redis Configuration

To change the Redis endpoint after deployment:

```bash
# Update the ConfigMap
kubectl create configmap redis-app-config \
    --from-literal=REDIS_URL="redis://NEW_HOST:NEW_PORT" \
    --from-literal=PORT="3000" \
    -n redis-app \
    --dry-run=client -o yaml | kubectl apply -f -

# Restart backend to pick up new config
kubectl rollout restart deployment/backend -n redis-app
```

## Useful Commands

```bash
# Check pod status
kubectl get pods -n redis-app

# Check services
kubectl get svc -n redis-app

# View backend logs
kubectl logs -n redis-app -l app=backend

# View frontend logs
kubectl logs -n redis-app -l app=frontend

# View Redis logs
kubectl logs -n redis-app -l app=redis

# Scale backend
kubectl scale deployment/backend -n redis-app --replicas=3
```

## Project Structure

```
.
├── backend/
│   ├── Dockerfile
│   ├── package.json
│   └── server.js
├── frontend/
│   ├── Dockerfile
│   ├── package.json
│   ├── server.js
│   └── public/
│       └── index.html
├── k8s/
│   ├── namespace.yaml
│   ├── configmap.yaml
│   ├── redis-deployment.yaml
│   ├── backend-deployment.yaml
│   └── frontend-deployment.yaml
├── deploy.sh
└── cleanup.sh
```

