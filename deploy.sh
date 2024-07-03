#!/bin/bash

# Set the namespace and deployment name
NAMESPACE1="default"
NAMESPACE2="ingress-nginx"
DEPLOYMENT_NAME="mywebapp-deployment"
SERVICE_NAME="mywebapp-service"
INGRESS_NAME="mywebapp-ingress"

# Ensure kubectl is configured correctly
export KUBECONFIG=${KUBECONFIG:-"$HOME/.kube/config"}

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace

# Deploy the application if it does not exist
if ! kubectl get deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE1" > /dev/null 2>&1; then
  echo "Creating new deployment..."
  sed -i "s|IMAGE_PLACEHOLDER|891377120087.dkr.ecr.us-east-1.amazonaws.com/rakbank:$1|" mywebapp/templates/deployment.yaml
  kubectl apply -f mywebapp/templates/deployment.yaml -n "$NAMESPACE1"
else
  echo "Updating deployment image to version $1..."
  kubectl set image deployment/"$DEPLOYMENT_NAME" mywebapp-container=891377120087.dkr.ecr.us-east-1.amazonaws.com/rakbank:$1 -n "$NAMESPACE1"
  if [ $? -ne 0 ]; then
    echo "Failed to update the deployment image. Please check your configuration."
    exit 1
  fi
fi

# Wait for deployment rollout to complete
echo "Waiting for deployment rollout to complete..."
kubectl rollout status deployment/"$DEPLOYMENT_NAME" -n "$NAMESPACE1" --timeout=5m
if [ $? -ne 0 ]; then
  echo "Deployment rollout failed or timed out."
  exit 1
fi

# Deploy the service
echo "Exposing application via service..."
kubectl apply -f mywebapp/templates/service.yaml -n "$NAMESPACE1"


# Deploy the ingress
echo "Creating Ingress for the application..."
kubectl apply -f mywebapp/templates/ingress.yaml -n "$NAMESPACE2"


echo "Deployment, service, and ingress creation completed successfully."
