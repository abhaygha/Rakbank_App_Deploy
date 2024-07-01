#!/bin/bash

# Set the namespace and deployment name
NAMESPACE="default"
DEPLOYMENT_NAME="myapp-deployment"

# Ensure kubectl is configured correctly
KUBE_CONFIG=${KUBECONFIG:-"$HOME/.kube/config"}

# Check if KUBECONFIG is set and the file exists
if [ -z "$KUBECONFIG" ] || [ ! -f "$KUBECONFIG" ]; then
  echo "KUBECONFIG is not set or the file does not exist."
  exit 1
fi

# Check connectivity to Kubernetes cluster
kubectl --kubeconfig="$KUBE_CONFIG" cluster-info > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "Failed to connect to Kubernetes cluster. Please check your KUBECONFIG."
  exit 1
fi

# Deploy the application
echo "Deploying application to Kubernetes..."
kubectl --kubeconfig="$KUBE_CONFIG" apply -f deployment.yaml -n "$NAMESPACE"

# Check deployment status
echo "Waiting for deployment rollout to complete..."
kubectl --kubeconfig="$KUBE_CONFIG" rollout status deployment/"$DEPLOYMENT_NAME" -n "$NAMESPACE"
if [ $? -ne 0 ]; then
  echo "Deployment rollout failed or timed out."
  exit 1
fi

echo "Deployment completed successfully."
