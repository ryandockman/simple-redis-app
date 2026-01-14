#!/bin/bash

set -e

# Parse command line arguments
REDIS_ENDPOINT=""
USE_EXTERNAL_REDIS=false
KIND_CLUSTER_NAME=""

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --redis-endpoint <host:port>   Use external Redis endpoint (e.g., 10.0.0.5:6379)"
    echo "  --kind-cluster <name>          Specify kind cluster name (auto-detects if not provided)"
    echo "  -h, --help                     Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Deploy with in-cluster Redis"
    echo "  $0 --redis-endpoint 10.0.0.5:6379    # Deploy with external Redis"
    echo "  $0 --kind-cluster kind                # Deploy to specific kind cluster"
    exit 1
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --redis-endpoint)
            REDIS_ENDPOINT="$2"
            USE_EXTERNAL_REDIS=true
            shift 2
            ;;
        --kind-cluster)
            KIND_CLUSTER_NAME="$2"
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

# Detect kind cluster name from Docker if not specified
if [ -z "$KIND_CLUSTER_NAME" ]; then
    # Try to detect from Docker container labels
    DETECTED_KIND=$(sudo docker ps --filter "label=io.x-k8s.kind.cluster" --format "{{.Label \"io.x-k8s.kind.cluster\"}}" 2>/dev/null | head -n 1)
    if [ -n "$DETECTED_KIND" ]; then
        KIND_CLUSTER_NAME="$DETECTED_KIND"
        echo "🔍 Detected kind cluster: $KIND_CLUSTER_NAME"
    fi
fi

# Load images into cluster
if command -v minikube &> /dev/null && minikube status &> /dev/null; then
    echo "🔄 Loading images into Minikube..."
    minikube image load redis-app-backend:latest
    minikube image load redis-app-frontend:latest
elif [ -n "$KIND_CLUSTER_NAME" ]; then
    echo "🔄 Loading images into kind cluster: $KIND_CLUSTER_NAME..."
    kind load docker-image redis-app-backend:latest --name "$KIND_CLUSTER_NAME" 2>&1 || {
        echo "⚠️  kind load failed, trying direct docker save/load to kind nodes..."
        # Fallback: save images and load directly into kind nodes
        sudo docker save redis-app-backend:latest | sudo docker exec -i "${KIND_CLUSTER_NAME}-control-plane" ctr -n k8s.io images import - 2>/dev/null || echo "⚠️  Failed to load backend image"
        sudo docker save redis-app-frontend:latest | sudo docker exec -i "${KIND_CLUSTER_NAME}-control-plane" ctr -n k8s.io images import - 2>/dev/null || echo "⚠️  Failed to load frontend image"

        # Also load to worker nodes if they exist
        for node in $(sudo docker ps --filter "name=${KIND_CLUSTER_NAME}-worker" --format "{{.Names}}" 2>/dev/null); do
            echo "  Loading images to $node..."
            sudo docker save redis-app-backend:latest | sudo docker exec -i "$node" ctr -n k8s.io images import - 2>/dev/null || true
            sudo docker save redis-app-frontend:latest | sudo docker exec -i "$node" ctr -n k8s.io images import - 2>/dev/null || true
        done
    }
elif command -v kind &> /dev/null; then
    # Try to detect kind cluster from kubectl context
    CURRENT_CONTEXT=$(kubectl config current-context 2>/dev/null || echo "")
    if [[ "$CURRENT_CONTEXT" == kind-* ]]; then
        KIND_CLUSTER=$(echo "$CURRENT_CONTEXT" | sed 's/^kind-//')
        echo "🔄 Loading images into kind cluster: $KIND_CLUSTER (detected from context)..."
        kind load docker-image redis-app-backend:latest --name "$KIND_CLUSTER" || echo "⚠️  Failed to load backend image"
        kind load docker-image redis-app-frontend:latest --name "$KIND_CLUSTER" || echo "⚠️  Failed to load frontend image"
    else
        # Fallback: try to get first available kind cluster
        KIND_CLUSTERS=$(kind get clusters 2>/dev/null || echo "")
        if [ -n "$KIND_CLUSTERS" ]; then
            KIND_CLUSTER=$(echo "$KIND_CLUSTERS" | head -n 1)
            echo "🔄 Loading images into kind cluster: $KIND_CLUSTER..."
            kind load docker-image redis-app-backend:latest --name "$KIND_CLUSTER" || echo "⚠️  Failed to load backend image"
            kind load docker-image redis-app-frontend:latest --name "$KIND_CLUSTER" || echo "⚠️  Failed to load frontend image"
        else
            echo "⚠️  Warning: Could not detect kind cluster. Use --kind-cluster flag to specify."
        fi
    fi
else
    echo "⚠️  Warning: Could not detect minikube or kind. Make sure images are available in your cluster."
    echo "💡 Tip: If using kind, specify cluster name with --kind-cluster flag"
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

