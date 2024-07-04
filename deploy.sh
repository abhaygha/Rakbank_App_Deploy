#!/bin/bash

# Set the namespace and deployment name
NAMESPACE1="default"
NAMESPACE2="ingress-nginx"
DEPLOYMENT_NAME="mywebapp-deployment"
SERVICE_NAME="mywebapp-service"
INGRESS_NAME="mywebapp-ingress"

export KUBECONFIG=$HOME/.kube/config

# Check if KUBECONFIG is pointing to the right context
kubectl config get-contexts

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace

# Deploy the application
echo "Creating or updating deployment..."
sed -i "s|IMAGE_PLACEHOLDER|891377120087.dkr.ecr.us-east-1.amazonaws.com/rakbank:$1|" mywebapp/templates/deployment.yaml
kubectl apply -f mywebapp/templates/deployment.yaml -n "$NAMESPACE1"

# Update deployment image
echo "Updating deployment image to version $1..."
kubectl set image deployment/"$DEPLOYMENT_NAME" mywebapp-container=891377120087.dkr.ecr.us-east-1.amazonaws.com/rakbank:$1 -n "$NAMESPACE1"

# Wait for deployment rollout to complete
echo "Waiting for deployment rollout to complete..."
kubectl rollout status deployment/"$DEPLOYMENT_NAME" -n "$NAMESPACE1" --timeout=5m

# Deploy the service
echo "Exposing application via service..."
kubectl apply -f mywebapp/templates/service.yaml -n "$NAMESPACE1"

# Deploy the ingress
echo "Creating Ingress for the application..."
kubectl apply -f mywebapp/templates/ingress.yaml -n "$NAMESPACE2"

echo "Deployment, service, and ingress creation completed successfully."
