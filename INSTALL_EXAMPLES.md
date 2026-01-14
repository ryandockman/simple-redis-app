# Installation Examples

## Quick Install (One-Liner)

### Install with in-cluster Redis
```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/simple-redis-app/main/install.sh | bash
```

### Install with external Redis
```bash
# Replace with your Redis IP and port
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/simple-redis-app/main/install.sh | bash -s -- --redis-endpoint 10.0.0.5:6379
```

### Uninstall
```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/simple-redis-app/main/install.sh | bash -s -- --cleanup
```

## Local Installation

### Clone and deploy with in-cluster Redis
```bash
git clone https://github.com/YOUR_USERNAME/simple-redis-app.git
cd simple-redis-app
./deploy.sh
```

### Clone and deploy with external Redis
```bash
git clone https://github.com/YOUR_USERNAME/simple-redis-app.git
cd simple-redis-app
./deploy.sh --redis-endpoint 192.168.1.100:6379
```

## Common Redis Endpoint Examples

### Local Redis (outside cluster)
```bash
./deploy.sh --redis-endpoint host.docker.internal:6379
```

### Redis in another namespace
```bash
./deploy.sh --redis-endpoint redis.production.svc.cluster.local:6379
```

### Redis Cloud / Managed Redis
```bash
./deploy.sh --redis-endpoint my-redis.cloud.redislabs.com:12345
```

### Redis with custom port
```bash
./deploy.sh --redis-endpoint 10.0.0.5:6380
```

## Access the Application

After installation, forward the port:
```bash
kubectl port-forward -n redis-app svc/frontend 8080:80
```

Then open in your browser:
```
http://localhost:8080
```

## Verify Installation

Check pods are running:
```bash
kubectl get pods -n redis-app
```

Check services:
```bash
kubectl get svc -n redis-app
```

View backend logs:
```bash
kubectl logs -n redis-app -l app=backend --tail=50
```

## Troubleshooting

### Backend can't connect to Redis
```bash
# Check backend logs
kubectl logs -n redis-app -l app=backend

# Verify ConfigMap
kubectl get configmap redis-app-config -n redis-app -o yaml

# Test Redis connectivity from a pod
kubectl run -it --rm redis-test --image=redis:alpine -n redis-app -- redis-cli -h YOUR_REDIS_HOST -p YOUR_REDIS_PORT ping
```

### Pods not starting
```bash
# Check pod status
kubectl describe pods -n redis-app

# Check events
kubectl get events -n redis-app --sort-by='.lastTimestamp'
```

### Update Redis endpoint after deployment
```bash
kubectl create configmap redis-app-config \
    --from-literal=REDIS_URL="redis://NEW_HOST:NEW_PORT" \
    --from-literal=PORT="3000" \
    -n redis-app \
    --dry-run=client -o yaml | kubectl apply -f -

kubectl rollout restart deployment/backend -n redis-app
```

