#!/bin/bash

echo "Reading credentials.env"
source ../credentials.env

# ================ Prereqs start
# Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# helm repo add jetstack https://charts.jetstack.io
helm repo add instana https://helm.instana.io/artifactory/rel-helm-customer-virtual --username _ --password $DOWNLOAD_KEY
helm repo update

# helm pull --version v1.18.2 jetstack/cert-manager
helm pull instana/cert-manager --version=1.18.2

helm install \
  cert-manager cert-manager-v1.18.2.tgz \
  --namespace cert-manager \
  --create-namespace \
  --version v1.18.2 \
  --set crds.enabled=true \
  --set prometheus.enabled=false \
  --set webhook.timeoutSeconds=4 