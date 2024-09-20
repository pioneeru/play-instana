#!/bin/bash

echo "Reading credentials.env"
source ../credentials.env
source ../artefacts.env

# download all charts:
helm repo add instana https://helm.instana.io/artifactory/rel-helm-customer-virtual --username _ --password $DOWNLOAD_KEY
helm repo update

# helm pull instana/postgres-operator --version=1.10.1
helm pull instana/cloudnative-pg --version=0.21.1   ### by doc: 0.20.0
helm pull instana/zookeeper-operator --version=${ZOOKEEPER_HELM_CHART_VERSION}
helm pull instana/strimzi-kafka-operator --version=0.41.0
helm pull instana/eck-operator --version=2.9.0
helm pull instana/cass-operator --version=0.45.2
helm pull instana/ibm-clickhouse-operator --version=v0.1.2
helm pull instana/beeinstana-operator --version=v1.58.0


${KUBECTL} instana license download --sales-key ${SALES_KEY}
