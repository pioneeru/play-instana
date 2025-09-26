#!/bin/bash

echo "Reading credentials.env"
source ../credentials.env
source ../artefacts.env

# download all charts:
helm repo add instana https://helm.instana.io/artifactory/rel-helm-customer-virtual --username _ --password $DOWNLOAD_KEY
helm repo update

#helm pull instana/zookeeper-operator --version=${ZOOKEEPER_HELM_CHART_VERSION}
helm pull instana/strimzi-kafka-operator --version=${KAFKA_HELM_CHART_VERSION}
helm pull instana/eck-operator --version=${ELASTIC_HELM_CHART_VERSION}
helm pull instana/cloudnative-pg --version=${POSTGRES_HELM_CHART_VERSION}
helm pull instana/cass-operator --version=${CASSANDRA_HELM_CHART_VERSION}
helm pull instana/ibm-clickhouse-operator --version=${CLICKHOUSE_HELM_CHART_VERSION}
helm pull instana/beeinstana-operator --version=${BEEINSTANA_HELM_CHART_VERSION}


${KUBECTL} instana license download --sales-key ${SALES_KEY}
