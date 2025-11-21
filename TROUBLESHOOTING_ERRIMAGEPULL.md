# Troubleshooting ErrImagePull Error

## Problem
```
NAME                         READY   STATUS         RESTARTS   AGE
llmops-app-8fcdssdff-9vqsb   0/1     ErrImagePull   0          66s
```

This means Kubernetes can't find or pull the Docker image `llmops-app:latest`.

## Solution Steps

### Step 1: Check Current Docker Environment

```bash
# Check if you're using Minikube's Docker
docker images | grep llmops-app

# If empty, you need to point to Minikube's Docker
eval $(minikube docker-env)

# Verify you're now using Minikube's Docker
docker images
```

### Step 2: Build Image with Minikube's Docker

**Important:** Make sure you're in the project directory and Minikube Docker is active:

```bash
# 1. Point Docker to Minikube (CRITICAL STEP)
eval $(minikube docker-env)

# 2. Verify you're using Minikube Docker
docker ps
# Should show Minikube containers

# 3. Navigate to your project directory
cd /path/to/ANIME-RECOMMENDER

# 4. Build the image
docker build -t llmops-app:latest .

# 5. Verify image was created
docker images | grep llmops-app
# Should show: llmops-app   latest   [image-id]   [size]   [time]
```

### Step 3: Check Pod Details for More Info

```bash
# Get detailed error information
kubectl describe pod llmops-app-8fcdssdff-9vqsb

# Check pod logs (if container started)
kubectl logs llmops-app-8fcdssdff-9vqsb

# Check events
kubectl get events --sort-by='.lastTimestamp'
```

### Step 4: Delete and Recreate Pod

After building the image correctly:

```bash
# Delete the existing pod (deployment will recreate it)
kubectl delete pod llmops-app-8fcdssdff-9vqsb

# Or delete the entire deployment and recreate
kubectl delete -f llmops-k8s.yaml
kubectl apply -f llmops-k8s.yaml

# Watch the new pod
kubectl get pods -w
```

### Step 5: Verify Image is Available to Minikube

```bash
# Make sure Minikube Docker is active
eval $(minikube docker-env)

# List images in Minikube
minikube image ls | grep llmops-app

# Or use docker directly
docker images | grep llmops-app
```

## Common Issues and Fixes

### Issue 1: Image Built with Wrong Docker Daemon

**Symptom:** Image exists locally but Minikube can't find it

**Fix:**
```bash
# Always set Minikube Docker environment BEFORE building
eval $(minikube docker-env)
docker build -t llmops-app:latest .
```

### Issue 2: ImagePullPolicy Mismatch

**Check your llmops-k8s.yaml:**
```yaml
imagePullPolicy: IfNotPresent  # ✅ Correct for local images
# NOT: Always (this tries to pull from registry)
```

### Issue 3: Minikube Docker Not Running

**Check:**
```bash
minikube status
# Should show: docker: Running

# If not, restart Minikube
minikube stop
minikube start
```

### Issue 4: Image Name Mismatch

**Verify the image name in llmops-k8s.yaml matches what you built:**
```yaml
image: llmops-app:latest  # Must match docker build -t llmops-app:latest
```

## Complete Deployment Script

Save this as `deploy.sh` and run it:

```bash
#!/bin/bash

echo "Step 1: Starting Minikube..."
minikube status || minikube start

echo "Step 2: Setting Docker to Minikube..."
eval $(minikube docker-env)

echo "Step 3: Building Docker image..."
docker build -t llmops-app:latest .

echo "Step 4: Verifying image..."
docker images | grep llmops-app

echo "Step 5: Creating secret..."
kubectl create secret generic llmops-secrets \
  --from-literal=GROQ_API_KEY="${GROQ_API_KEY}" \
  --from-literal=HUGGINGFACEHUB_API_TOKEN="${HUGGINGFACEHUB_API_TOKEN}" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "Step 6: Deploying to Kubernetes..."
kubectl apply -f llmops-k8s.yaml

echo "Step 7: Waiting for pods..."
kubectl wait --for=condition=ready pod -l app=llmops --timeout=300s

echo "Step 8: Checking pod status..."
kubectl get pods

echo "Done! Check pod logs with: kubectl logs -l app=llmops"
```

Make it executable:
```bash
chmod +x deploy.sh
./deploy.sh
```

## Quick Fix Commands

```bash
# 1. Point to Minikube Docker
eval $(minikube docker-env)

# 2. Rebuild image
docker build -t llmops-app:latest .

# 3. Delete and recreate deployment
kubectl delete -f llmops-k8s.yaml
kubectl apply -f llmops-k8s.yaml

# 4. Watch pods
kubectl get pods -w
```

## Alternative: Use Minikube Image Load

If building directly doesn't work:

```bash
# Build image with regular Docker
docker build -t llmops-app:latest .

# Load into Minikube
minikube image load llmops-app:latest

# Verify
minikube image ls | grep llmops-app
```

