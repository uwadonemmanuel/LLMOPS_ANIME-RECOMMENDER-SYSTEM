# GCP Deployment Guide - Fixing kubectl Connection Issues

## Problem
When running `kubectl` commands from GCP Console, you get:
```
error: failed to create secret Post "https://192.168.49.2:8443/api/v1/namespaces/default/secrets?fieldManager=kubectl-create&fieldValidation=Strict": dial tcp 192.168.49.2:8443: connect: no route to host
```

This happens because:
- `kubectl` is trying to connect to a local Minikube cluster (192.168.49.2:8443)
- You're running commands from GCP Console, not from the VM where Minikube is running
- Minikube cluster is only accessible from within the VM

## Solution: Run Commands on the VM

### Step 1: SSH into Your GCP VM

**Option A: From GCP Console**
1. Go to **Compute Engine** → **VM instances**
2. Find your VM instance
3. Click **SSH** button (opens browser-based SSH)

**Option B: From Local Terminal**
```bash
gcloud compute ssh [VM_INSTANCE_NAME] --zone=[ZONE]
```

### Step 2: Verify Minikube is Running

Once connected to the VM, run:
```bash
# Check Minikube status
minikube status

# If not running, start it
minikube start

# Verify kubectl can connect
kubectl cluster-info
kubectl get nodes
```

### Step 3: Create the Secret (On the VM)

**Important:** Run these commands **on the VM**, not from GCP Console:

```bash
# Replace with your actual API keys
kubectl create secret generic llmops-secrets \
  --from-literal=GROQ_API_KEY="your_groq_api_key_here" \
  --from-literal=HUGGINGFACEHUB_API_TOKEN="your_huggingface_token_here"
```

**Or if the secret already exists, delete and recreate:**
```bash
# Delete existing secret (if any)
kubectl delete secret llmops-secrets

# Create new secret
kubectl create secret generic llmops-secrets \
  --from-literal=GROQ_API_KEY="your_groq_api_key_here" \
  --from-literal=HUGGINGFACEHUB_API_TOKEN="your_huggingface_token_here"

# Verify secret was created
kubectl get secret llmops-secrets
kubectl describe secret llmops-secrets
```

### Step 4: Complete Deployment (On the VM)

```bash
# Point Docker to Minikube
eval $(minikube docker-env)

# Build the Docker image
docker build -t llmops-app:latest .

# Apply Kubernetes deployment
kubectl apply -f llmops-k8s.yaml

# Check pods
kubectl get pods

# Check services
kubectl get services
```

### Step 5: Access Your Application

**Terminal 1 - Start Minikube Tunnel:**
```bash
minikube tunnel
# Keep this running
```

**Terminal 2 - Port Forward:**
```bash
kubectl port-forward svc/llmops-service 8501:80 --address 0.0.0.0
```

**Get External IP:**
```bash
# Get VM external IP
curl ifconfig.me
# Or check in GCP Console: Compute Engine → VM instances → External IP
```

Access your app at: `http://[VM_EXTERNAL_IP]:8501`

## Alternative: Using GKE (Google Kubernetes Engine)

If you want to use GKE instead of Minikube:

### 1. Create GKE Cluster
```bash
gcloud container clusters create llmops-cluster \
  --num-nodes=2 \
  --zone=us-central1-a \
  --machine-type=e2-standard-2
```

### 2. Get Cluster Credentials
```bash
gcloud container clusters get-credentials llmops-cluster --zone=us-central1-a
```

### 3. Verify Connection
```bash
kubectl cluster-info
kubectl get nodes
```

### 4. Create Secret
```bash
kubectl create secret generic llmops-secrets \
  --from-literal=GROQ_API_KEY="your_groq_api_key_here" \
  --from-literal=HUGGINGFACEHUB_API_TOKEN="your_huggingface_token_here"
```

### 5. Deploy
```bash
# Build and push to GCR or Artifact Registry
docker build -t gcr.io/[PROJECT_ID]/llmops-app:latest .
docker push gcr.io/[PROJECT_ID]/llmops-app:latest

# Update llmops-k8s.yaml to use the GCR image
# Then apply
kubectl apply -f llmops-k8s.yaml
```

## Troubleshooting

### Check Current kubectl Context
```bash
kubectl config current-context
kubectl config get-contexts
```

### Switch Context (if needed)
```bash
# For Minikube
kubectl config use-context minikube

# For GKE
kubectl config use-context gke_[PROJECT_ID]_[ZONE]_[CLUSTER_NAME]
```

### Verify Minikube is Accessible
```bash
# Check if Minikube is running
minikube status

# Restart if needed
minikube stop
minikube start

# Get Minikube IP
minikube ip
```

### Check Firewall Rules (GCP)
If accessing from outside, ensure firewall allows port 8501:
```bash
gcloud compute firewall-rules create allow-streamlit \
  --allow tcp:8501 \
  --source-ranges 0.0.0.0/0 \
  --description "Allow Streamlit port"
```

## Quick Reference

**Always run kubectl commands on the VM where Minikube is running, not from GCP Console!**

```bash
# 1. SSH into VM
gcloud compute ssh [VM_NAME] --zone=[ZONE]

# 2. Start Minikube (if not running)
minikube start

# 3. Create secret
kubectl create secret generic llmops-secrets \
  --from-literal=GROQ_API_KEY="..." \
  --from-literal=HUGGINGFACEHUB_API_TOKEN="..."

# 4. Deploy
kubectl apply -f llmops-k8s.yaml

# 5. Check status
kubectl get pods
kubectl get services
```

