#!/bin/bash

echo "=== Cluster Detection Debug ==="
echo ""

echo "Current kubectl context:"
kubectl config current-context 2>/dev/null || echo "  (none)"
echo ""

echo "Kind clusters:"
kind get clusters 2>/dev/null || echo "  kind command not available or no clusters found"
echo ""

echo "Docker containers (looking for kind nodes):"
sudo docker ps --filter "label=io.x-k8s.kind.cluster" --format "table {{.Names}}\t{{.Image}}\t{{.Labels}}" 2>/dev/null || echo "  Could not list docker containers"
echo ""

echo "Kubectl cluster info:"
kubectl cluster-info 2>/dev/null || echo "  Could not get cluster info"
echo ""

echo "Checking for kind cluster label in docker:"
sudo docker ps --filter "label=io.x-k8s.kind.cluster" --format "{{.Label \"io.x-k8s.kind.cluster\"}}" 2>/dev/null | head -n 1

