#!/bin/bash

echo "Reading credentials.env"
source ../credentials.env

# ================ Prereqs start
# Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

helm repo add jetstack https://charts.jetstack.io
helm repo update

helm pull --version v1.11.0 jetstack/cert-manager

helm install \
  cert-manager cert-manager-v1.11.0.tgz \
  --namespace cert-manager \
  --create-namespace \
  --version v1.11.0 \
  --set installCRDs=true \
  --set prometheus.enabled=false \
  --set webhook.timeoutSeconds=4 