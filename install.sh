#!/bin/bash

set -e

# Configuration
REPO_URL="https://github.com/ryandockman/simple-redis-app"
REPO_NAME="simple-redis-app"
BRANCH="main"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Parse command line arguments
REDIS_ENDPOINT=""
CLEANUP=false

usage() {
    echo "Simple Redis App - Kubernetes Installer"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --redis-endpoint <host:port>   Use external Redis endpoint (e.g., 10.0.0.5:6379)"
    echo "  --cleanup                      Remove the application from Kubernetes"
    echo "  -h, --help                     Show this help message"
    echo ""
    echo "Examples:"
    echo "  # Install with in-cluster Redis:"
    echo "  curl -fsSL https://raw.githubusercontent.com/ryandockman/simple-redis-app/main/install.sh | bash"
    echo ""
    echo "  # Install with external Redis:"
    echo "  curl -fsSL https://raw.githubusercontent.com/ryandockman/simple-redis-app/main/install.sh | bash -s -- --redis-endpoint 10.0.0.5:6379"
    echo ""
    echo "  # Cleanup:"
    echo "  curl -fsSL https://raw.githubusercontent.com/ryandockman/simple-redis-app/main/install.sh | bash -s -- --cleanup"
    exit 1
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --redis-endpoint)
            REDIS_ENDPOINT="$2"
            shift 2
            ;;
        --cleanup)
            CLEANUP=true
            shift
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

# Check prerequisites
check_prerequisites() {
    echo -e "${YELLOW}Checking prerequisites...${NC}"
    
    if ! command -v kubectl &> /dev/null; then
        echo -e "${RED}Error: kubectl is not installed${NC}"
        exit 1
    fi
    
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}Error: docker is not installed${NC}"
        exit 1
    fi
    
    if ! kubectl cluster-info &> /dev/null; then
        echo -e "${RED}Error: Cannot connect to Kubernetes cluster${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✓ All prerequisites met${NC}"
}

# Cleanup function
cleanup_app() {
    echo -e "${YELLOW}🧹 Cleaning up Redis App from Kubernetes...${NC}"
    kubectl delete namespace redis-app --ignore-not-found=true
    echo -e "${GREEN}✅ Cleanup complete!${NC}"
    exit 0
}

# Main installation
main() {
    if [ "$CLEANUP" = true ]; then
        cleanup_app
    fi
    
    check_prerequisites
    
    echo -e "${GREEN}🚀 Installing Simple Redis App${NC}"
    
    # Create temporary directory
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    
    echo -e "${YELLOW}📥 Downloading application...${NC}"

    # Download the repository as tarball (works for public repos without authentication)
    curl -fsSL "${REPO_URL}/archive/refs/heads/${BRANCH}.tar.gz" -o repo.tar.gz
    tar -xzf repo.tar.gz
    mv "${REPO_NAME}-${BRANCH}" "$REPO_NAME"
    
    cd "$REPO_NAME"
    
    # Run deployment
    echo -e "${YELLOW}🚀 Deploying to Kubernetes...${NC}"
    
    if [ -n "$REDIS_ENDPOINT" ]; then
        ./deploy.sh --redis-endpoint "$REDIS_ENDPOINT"
    else
        ./deploy.sh
    fi
    
    # Cleanup temp directory
    cd /
    rm -rf "$TEMP_DIR"
    
    echo ""
    echo -e "${GREEN}✅ Installation complete!${NC}"
    echo ""
    echo -e "${YELLOW}To access the application:${NC}"
    echo "  kubectl port-forward -n redis-app svc/frontend 8080:80"
    echo "  Then open http://localhost:8080 in your browser"
    echo ""
    echo -e "${YELLOW}To uninstall:${NC}"
    echo "  curl -fsSL https://raw.githubusercontent.com/ryandockman/simple-redis-app/main/install.sh | bash -s -- --cleanup"
}

main

