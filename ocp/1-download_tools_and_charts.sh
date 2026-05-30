#!/bin/bash

echo "Reading credentials.env"
source ../credentials.env
source ../artifacts-${BASTION_PLATFORM}.env

mkdir -p ${INSTANA_AIRGAPPED_FOLDER}

# Helm
#curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
### Install helm on host with the Internet
### required to download helm charts
echo "Installing helm here to pull charts..."
wget https://mirror.openshift.com/pub/openshift-v4/clients/helm/latest/helm-linux-${INTENET_HOST_PLATFORM} -O /usr/local/bin/helm
chmod +x /usr/local/bin/helm
### Prepare helm for air-gapped bastion
echo "Downloading helm for bastion node to install pulled charts..."
wget "https://mirror.openshift.com/pub/openshift-v4/clients/helm/latest/helm-linux-${BASTION_PLATFORM}" -O ${INSTANA_AIRGAPPED_FOLDER}/helm-linux-${BASTION_PLATFORM}


# Kubectl plugin
## check current version:
## https://artifact-public.instana.io/artifactory/rel-rpm-public-virtual/
## Manual download:
# yum makecache -y
# yum install -y 'dnf-command(versionlock)'
# # yum --showduplicates list instana-kubectl-plugin | expand
# yum versionlock delete instana-kubectl-plugin
# yum versionlock delete instana-kubectl
# yum remove -y instana-kubectl
# yum install -y ${KUBECTL_INSTANA_PLUGIN}
# yum versionlock add instana-kubectl-plugin
## using wget:
## https://artifact-public.instana.io/artifactory/rel-generic-instana-virtual/infrastructure/kubectl/instana-kubectl-plugin-linux_amd64-1.1.0.tar.gz
echo "Downloading ${KUBECTL_INSTANA_PLUGIN}..."
wget ${KUBECTL_INSTANA_PLUGIN_URL}/${KUBECTL_INSTANA_PLUGIN} -P ${INSTANA_AIRGAPPED_FOLDER} --user=_ --password=${DOWNLOAD_KEY}


# Download yq:
echo "Downloading yq_linux_${BASTION_PLATFORM}..."
wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_${BASTION_PLATFORM} -O ${INSTANA_AIRGAPPED_FOLDER}/yq_linux_${BASTION_PLATFORM}


# Download helm charts:
echo "Pulling helm charts..."
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/
helm repo add instana https://helm.instana.io/artifactory/rel-helm-customer-virtual --username _ --password $DOWNLOAD_KEY
helm repo update

helm pull nfs-subdir-external-provisioner/nfs-subdir-external-provisioner --version=${NFS_CLIENT_HELM_CHART_VERSION} -d ${INSTANA_AIRGAPPED_FOLDER}

helm pull instana/cert-manager --version=${CERT_MANAGER_HELM_CHART_VERSION} -d ${INSTANA_AIRGAPPED_FOLDER}

if [[ "${INSTANA_PLATFORM}" == "s390x" ]]; then
    helm pull instana/zookeeper-operator --version=${ZOOKEEPER_HELM_CHART_VERSION} -d ${INSTANA_AIRGAPPED_FOLDER}
fi
helm pull instana/strimzi-kafka-operator --version=${KAFKA_HELM_CHART_VERSION} -d ${INSTANA_AIRGAPPED_FOLDER}
helm pull instana/eck-operator --version=${ELASTIC_HELM_CHART_VERSION} -d ${INSTANA_AIRGAPPED_FOLDER}
helm pull instana/cloudnative-pg --version=${POSTGRES_HELM_CHART_VERSION} -d ${INSTANA_AIRGAPPED_FOLDER}
helm pull instana/cass-operator --version=${CASSANDRA_HELM_CHART_VERSION} -d ${INSTANA_AIRGAPPED_FOLDER}
helm pull instana/ibm-clickhouse-operator --version=${CLICKHOUSE_HELM_CHART_VERSION} -d ${INSTANA_AIRGAPPED_FOLDER}
helm pull instana/beeinstana-operator --version=${BEEINSTANA_HELM_CHART_VERSION} -d ${INSTANA_AIRGAPPED_FOLDER}

${KUBECTL} instana license download --sales-key ${SALES_KEY}
# Download license
echo "Downloading license..."
wget https://instana.io/onprem/license/download/v2/allValid?salesId=${SALES_KEY} -O ${INSTANA_AIRGAPPED_FOLDER}/license.json
