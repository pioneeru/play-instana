#!/bin/bash

echo "Reading credentials.env"
source ../credentials.env
source ../artifacts-${INSTANA_PLATFORM}.env

# Install NFS client - if needed
if [[ -z "${NFS_SERVER_IP}" && -z "${NFS_SERVER_PATH}" ]]; then
   echo "Installing or upgrading nfs-subdir-external-provisioner-${NFS_CLIENT_HELM_CHART_VERSION}..."
   helm upgrade --install nfs-subdir-external-provisioner nfs-subdir-external-provisioner-${NFS_CLIENT_HELM_CHART_VERSION}.tgz \
      -n default \
      --set nfs.server=${NFS_SERVER_IP} \
      --set nfs.path=${NFS_SERVER_PATH}
else
   echo "Skipping install or upgrade for nfs-client..."
fi

# Install cert manager
echo "Installing or upgrading cert-manager-v${CERT_MANAGER_HELM_CHART_VERSION}..."
helm upgrade --install cert-manager cert-manager-v${CERT_MANAGER_HELM_CHART_VERSION}.tgz \
  --create-namespace --namespace=cert-manager \
  --set crds.enabled=true \
  --set prometheus.enabled=false \
  --set webhook.timeoutSeconds=5

