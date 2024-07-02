#!/bin/bash

# Set the namespace and deployment name
NAMESPACE="default"
DEPLOYMENT_NAME="mywebapp-deployment"

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

# Deploy the application if it does not exist
kubectl --kubeconfig="$KUBE_CONFIG" get deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE"
if [ $? -ne 0 ]; then
  echo "Creating new deployment..."
  sed -i "s|IMAGE_PLACEHOLDER|891377120087.dkr.ecr.us-east-1.amazonaws.com/rakbank:$1|" mywebapp/templates/deployment.yaml
  kubectl --kubeconfig="$KUBE_CONFIG" apply -f mywebapp/templates/deployment.yaml -n "$NAMESPACE"
else
  echo "Updating deployment image to version $1..."
  kubectl --kubeconfig="$KUBE_CONFIG" set image deployment/"$DEPLOYMENT_NAME" mywebapp-container=891377120087.dkr.ecr.us-east-1.amazonaws.com/rakbank:$1 -n "$NAMESPACE"
  if [ $? -ne 0 ]; then
    echo "Failed to update the deployment image. Please check your configuration."
    exit 1
  fi
fi

# Check deployment status
echo "Waiting for deployment rollout to complete..."
kubectl --kubeconfig="$KUBE_CONFIG" rollout status deployment/"$DEPLOYMENT_NAME" -n "$NAMESPACE" --timeout=5m
if [ $? -ne 0 ]; then
  echo "Deployment rollout failed or timed out."
  exit 1
fi

# Deploy the service
echo "Exposing application via service..."
kubectl --kubeconfig="$KUBE_CONFIG" apply -f mywebapp/templates/service.yaml -n "$NAMESPACE"

# Check service status
echo "Waiting for service to be created..."
kubectl --kubeconfig="$KUBE_CONFIG" wait --for=condition=available --timeout=60s service/"$DEPLOYMENT_NAME" -n "$NAMESPACE"
if [ $? -ne 0 ]; then
  echo "Service creation failed or timed out."
  exit 1
fi

# Deploy the ingress
echo "Creating Ingress for the application..."
kubectl --kubeconfig="$KUBE_CONFIG" apply -f mywebapp/templates/ingress.yaml -n "$NAMESPACE"

# Check ingress status
echo "Waiting for Ingress to be created..."
kubectl --kubeconfig="$KUBE_CONFIG" wait --for=condition=ready --timeout=60s ingress/"mywebapp-ingress" -n "$NAMESPACE"
if [ $? -ne 0 ]; then
  echo "Ingress creation failed or timed out."
  exit 1
fi

echo "Deployment, service, and ingress creation completed successfully."
