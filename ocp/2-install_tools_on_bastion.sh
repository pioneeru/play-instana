#!/bin/bash

echo "Reading credentials.env"
source ../credentials.env
source ../artifacts-${BASTION_PLATFORM}.env

### Install helm on bastion node from air-gapped folder
echo "Installing helm..."
cp ${INSTANA_AIRGAPPED_FOLDER}/helm-linux-${BASTION_PLATFORM} /usr/local/bin/helm
chmod +x /usr/local/bin/helm


# Kubectl plugin
echo "Installing ${KUBECTL_INSTANA_PLUGIN}..."
tar xzvf ${INSTANA_AIRGAPPED_FOLDER}/${KUBECTL_INSTANA_PLUGIN} -C /usr/local/bin/
kubectl instana --version


# Install yq
echo "Installing yq_linux_${BASTION_PLATFORM}..."
cp ${INSTANA_AIRGAPPED_FOLDER}/yq_linux_${BASTION_PLATFORM} /usr/local/bin/yq
sudo chmod +x /usr/local/bin/yq

