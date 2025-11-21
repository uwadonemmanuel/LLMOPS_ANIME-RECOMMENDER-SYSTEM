#!/bin/bash

echo "=== Fixing ErrImagePull Issue ==="

echo ""
echo "Step 1: Checking current pod status..."
kubectl get pods

echo ""
echo "Step 2: Getting detailed pod information..."
POD_NAME=$(kubectl get pods -l app=llmops -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -n "$POD_NAME" ]; then
    echo "Pod name: $POD_NAME"
    kubectl describe pod $POD_NAME | grep -A 10 "Events:"
else
    echo "No pod found with label app=llmops"
fi

echo ""
echo "Step 3: Verifying image exists in Minikube..."
eval $(minikube docker-env)
docker images | grep llmops-app

echo ""
echo "Step 4: Restarting deployment..."
kubectl rollout restart deployment llmops-app

echo ""
echo "Step 5: Waiting for new pod..."
sleep 5
kubectl get pods -w &
WATCH_PID=$!

echo ""
echo "Step 6: Checking new pod status (waiting 30 seconds)..."
sleep 30
kill $WATCH_PID 2>/dev/null

echo ""
echo "Step 7: Final pod status..."
kubectl get pods

echo ""
echo "Step 8: If still failing, checking events..."
kubectl get events --sort-by='.lastTimestamp' | tail -10

echo ""
echo "=== Done ==="
echo "If pod is still in ErrImagePull, run: kubectl describe pod [POD_NAME]"

