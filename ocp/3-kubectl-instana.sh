#!/bin/bash

echo "Reading credentials.env"
source ../artefacts.env
source ../credentials.env

# Kubectl plugin

cat << EOF > /etc/yum.repos.d/Instana-Product.repo
[instana-product]
name=Instana-Product
baseurl=https://_:$DOWNLOAD_KEY@artifact-public.instana.io/artifactory/rel-rpm-public-virtual/
enabled=1
gpgcheck=0
gpgkey=https://_:$DOWNLOAD_KEY@artifact-public.instana.io/artifactory/api/security/keypair/public/repositories/rel-rpm-public-virtual
repo_gpgcheck=1
EOF

## check current version:
## https://artifact-public.instana.io/artifactory/rel-rpm-public-virtual/


yum makecache -y
yum install -y 'dnf-command(versionlock)'
# yum --showduplicates list instana-kubectl-plugin | expand

yum versionlock delete instana-kubectl-plugin
yum versionlock delete instana-kubectl
yum remove -y instana-kubectl
yum install -y ${KUBECTL_INSTANA_PLUGIN}
yum versionlock add instana-kubectl-plugin

kubectl instana --version