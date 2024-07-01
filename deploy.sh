#!/bin/bash

# Set the namespace and deployment name
NAMESPACE="default"
DEPLOYMENT_NAME="myapp-deployment"

echo "Current KUBECONFIG: $KUBE_CONFIG"
echo "Environment variables:"
env

# Ensure kubectl is configured correctly
KUBE_CONFIG=${KUBECONFIG:-"$HOME/.kube/config"}

# Check if KUBECONFIG is set and the file exists
if [ -z "$KUBECONFIG" ] || [ ! -f "$KUBE_CONFIG" ]; then
  echo "KUBECONFIG is not set or the file does not exist. Setting it explicitly."
  # Set KUBECONFIG explicitly based on your configuration
  KUBE_CONFIG="$HOME/.kube/config"  # Adjust this if your KUBECONFIG is stored elsewhere
fi

# Check connectivity to Kubernetes cluster
kubectl --kubeconfig="$KUBE_CONFIG" cluster-info > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "Failed to connect to Kubernetes cluster. Please check your KUBECONFIG."
  exit 1
fi

# Deploy the application
echo "Deploying application to Kubernetes..."
kubectl --kubeconfig="$KUBE_CONFIG" apply -f mywebapp/templates/deployment.yaml -n "$NAMESPACE"

# Check deployment status
echo "Waiting for deployment rollout to complete..."
kubectl --kubeconfig="$KUBE_CONFIG" rollout status deployment/"$DEPLOYMENT_NAME" -n "$NAMESPACE"
if [ $? -ne 0 ]; then
  echo "Deployment rollout failed or timed out."
  exit 1
fi

echo "Exposing application via service..."
kubectl --kubeconfig="$KUBE_CONFIG" apply -f myapp/templates/service.yaml -n "$NAMESPACE"

# Check service status
echo "Waiting for service to be created..."
kubectl --kubeconfig="$KUBE_CONFIG" wait --for=condition=available --timeout=60s service/"$DEPLOYMENT_NAME" -n "$NAMESPACE"
if [ $? -ne 0 ]; then
  echo "Service creation failed or timed out."
  exit 1
fi

echo "Service creation completed successfully."

echo "Deployment and service creation completed successfully."
