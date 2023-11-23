#!/bin/bash

echo "Reading config.env"
source ../credentials.env

# ================ Prereqs start
# Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# NFS client - if needed
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/
helm repo update
helm install nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
   -n default \
   --set nfs.server=${NFS_SERVER_IP} \
   --set nfs.path=${NFS_SERVER_PATH}


