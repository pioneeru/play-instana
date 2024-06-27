#!/bin/bash

echo "Reading credentials.env"
source ../credentials.env

# download all charts:
helm repo add pravega https://charts.pravega.io
helm repo add strimzi https://strimzi.io/charts/
helm repo add elastic https://helm.elastic.co
helm repo add cnpg https://cloudnative-pg.github.io/charts
helm repo add k8ssandra https://helm.k8ssandra.io/stable
helm repo add instana https://helm.instana.io/artifactory/rel-helm-customer-virtual --username _ --password $DOWNLOAD_KEY
helm repo update

helm pull pravega/zookeeper-operator --version=0.2.15
helm pull strimzi/strimzi-kafka-operator --version 0.38.0
helm pull elastic/eck-operator --version=2.9.0
helm pull cnpg/cloudnative-pg --version=0.20.0
helm pull k8ssandra/cass-operator --version=0.45.2
helm pull instana/ibm-clickhouse-operator --version=v0.1.2
helm pull instana/beeinstana-operator --version=v1.47.0

${KUBECTL} instana license download --sales-key ${SALES_KEY}
