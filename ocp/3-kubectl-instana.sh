#!/bin/bash

echo "Reading credentials.env"
source ../credentials.env
source ../artefacts.env

# Kubectl plugin

## yum
# cat << EOF > /etc/yum.repos.d/Instana-Product.repo
# [instana-product]
# name=Instana-Product
# baseurl=https://_:$DOWNLOAD_KEY@artifact-public.instana.io/artifactory/rel-rpm-public-virtual/
# enabled=1
# gpgcheck=0
# gpgkey=https://_:$DOWNLOAD_KEY@artifact-public.instana.io/artifactory/api/security/keypair/public/repositories/rel-rpm-public-virtual
# repo_gpgcheck=1
# EOF

## check current version:
## https://artifact-public.instana.io/artifactory/rel-rpm-public-virtual/


# yum makecache -y
# yum install -y 'dnf-command(versionlock)'
# # yum --showduplicates list instana-kubectl-plugin | expand

# yum versionlock delete instana-kubectl-plugin
# yum versionlock delete instana-kubectl
# yum remove -y instana-kubectl
# yum install -y ${KUBECTL_INSTANA_PLUGIN}
# yum versionlock add instana-kubectl-plugin


## wget
## check current version:
## https://artifact-public.instana.io/artifactory/rel-generic-instana-virtual/infrastructure/kubectl/instana-kubectl-plugin-linux_amd64-1.1.0.tar.gz

wget ${KUBECTL_INSTANA_PLUGIN_URL}/${KUBECTL_INSTANA_PLUGIN} -P /tmp --user=_ --password=${DOWNLOAD_KEY}
tar xzvf /tmp/${KUBECTL_INSTANA_PLUGIN} -C /usr/local/bin/

kubectl instana --version