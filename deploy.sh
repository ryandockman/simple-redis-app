#!/bin/bash

set -e

# Parse command line arguments
REDIS_ENDPOINT=""
USE_EXTERNAL_REDIS=false

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --redis-endpoint <host:port>   Use external Redis endpoint (e.g., 10.0.0.5:6379)"
    echo "  -h, --help                     Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Deploy with in-cluster Redis"
    echo "  $0 --redis-endpoint 10.0.0.5:6379    # Deploy with external Redis"
    exit 1
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --redis-endpoint)
            REDIS_ENDPOINT="$2"
            USE_EXTERNAL_REDIS=true
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

echo "🚀 Deploying Redis App to Kubernetes..."

# Build Docker images
echo "📦 Building Docker images..."
sudo docker build -t redis-app-backend:latest ./backend
sudo docker build -t redis-app-frontend:latest ./frontend

# If using minikube, load images into minikube
if command -v minikube &> /dev/null && minikube status &> /dev/null; then
    echo "🔄 Loading images into Minikube..."
    minikube image load redis-app-backend:latest
    minikube image load redis-app-frontend:latest
fi

# Create namespace
echo "📁 Creating namespace..."
kubectl apply -f k8s/namespace.yaml

# Create ConfigMap with Redis endpoint
echo "⚙️  Creating ConfigMap..."
if [ "$USE_EXTERNAL_REDIS" = true ]; then
    echo "Using external Redis endpoint: $REDIS_ENDPOINT"
    kubectl create configmap redis-app-config \
        --from-literal=REDIS_URL="redis://${REDIS_ENDPOINT}" \
        --from-literal=PORT="3000" \
        -n redis-app \
        --dry-run=client -o yaml | kubectl apply -f -
else
    echo "Using in-cluster Redis"
    kubectl apply -f k8s/configmap.yaml
fi

# Deploy Redis (only if using in-cluster Redis)
if [ "$USE_EXTERNAL_REDIS" = false ]; then
    echo "🔴 Deploying Redis..."
    kubectl apply -f k8s/redis-deployment.yaml
fi

# Deploy Backend
echo "🔧 Deploying Backend..."
kubectl apply -f k8s/backend-deployment.yaml

# Deploy Frontend
echo "🎨 Deploying Frontend..."
kubectl apply -f k8s/frontend-deployment.yaml

# Wait for deployments to be ready
echo "⏳ Waiting for deployments to be ready..."
if [ "$USE_EXTERNAL_REDIS" = false ]; then
    kubectl wait --for=condition=available --timeout=120s deployment/redis -n redis-app
fi
kubectl wait --for=condition=available --timeout=120s deployment/backend -n redis-app
kubectl wait --for=condition=available --timeout=120s deployment/frontend -n redis-app

echo "✅ Deployment complete!"
echo ""
echo "📊 Deployment status:"
kubectl get pods -n redis-app
echo ""
echo "🌐 Services:"
kubectl get svc -n redis-app
echo ""
echo "To access the frontend:"
echo "  kubectl port-forward -n redis-app svc/frontend 8080:80"
echo "  Then open http://localhost:8080 in your browser"

