# Quick Start Guide

## 🚀 Install in 30 Seconds

### Option 1: With In-Cluster Redis (Simplest)
```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/simple-redis-app/main/install.sh | bash
```

### Option 2: With Your Own Redis Endpoint
```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/simple-redis-app/main/install.sh | bash -s -- --redis-endpoint YOUR_REDIS_IP:6379
```

Replace `YOUR_REDIS_IP` with your Redis server IP address.

## 🌐 Access the App

After installation completes, run:
```bash
kubectl port-forward -n redis-app svc/frontend 8080:80
```

Open your browser to: **http://localhost:8080**

## 🎯 What You'll See

- A beautiful web interface
- A button to add sample data to Redis
- A list showing all data stored in Redis
- Delete buttons to remove individual items

## 🧹 Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/simple-redis-app/main/install.sh | bash -s -- --cleanup
```

## 📋 Prerequisites

- Kubernetes cluster running (minikube, kind, GKE, EKS, AKS, etc.)
- `kubectl` installed and configured
- `docker` installed (for building images)

## 💡 Common Use Cases

### Use Case 1: Testing with Local Redis
```bash
# If you have Redis running locally on your machine
./deploy.sh --redis-endpoint host.docker.internal:6379
```

### Use Case 2: Production Redis
```bash
# Connect to your production Redis instance
./deploy.sh --redis-endpoint prod-redis.example.com:6379
```

### Use Case 3: Redis in Another K8s Namespace
```bash
# Connect to Redis in the 'database' namespace
./deploy.sh --redis-endpoint redis.database.svc.cluster.local:6379
```

## 🔍 Verify Everything Works

```bash
# Check all pods are running
kubectl get pods -n redis-app

# You should see:
# - backend pods (2 replicas)
# - frontend pods (2 replicas)
# - redis pod (if using in-cluster Redis)
```

## 🆘 Need Help?

See [INSTALL_EXAMPLES.md](INSTALL_EXAMPLES.md) for more examples and troubleshooting.

