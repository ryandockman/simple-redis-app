#!/bin/bash

set -e

echo "🧹 Cleaning up Redis App from Kubernetes..."

# Delete all resources in the namespace
kubectl delete namespace redis-app --ignore-not-found=true

echo "✅ Cleanup complete!"

