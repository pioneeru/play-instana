#!/bin/bash

echo "Reading config.env"
source ../credentials.env

# download all charts:

helm repo add pravega https://charts.pravega.io
helm repo add strimzi https://strimzi.io/charts/
helm repo add elastic https://helm.elastic.co
helm repo add postgres https://opensource.zalando.com/postgres-operator/charts/postgres-operator
helm repo add k8ssandra https://helm.k8ssandra.io/stable
helm repo add clickhouse-operator https://docs.altinity.com/clickhouse-operator/
helm repo add instana https://helm.instana.io/artifactory/rel-helm-customer-virtual --username _ --password $DOWNLOAD_KEY
helm repo update

helm pull pravega/zookeeper-operator --version=0.2.15
helm pull strimzi/strimzi-kafka-operator --version 0.36.0
helm pull elastic/eck-operator --version=2.8.0
helm pull postgres/postgres-operator --version=1.10.0
helm pull k8ssandra/cass-operator --version=0.42.0
helm pull clickhouse-operator/altinity-clickhouse-operator --version=0.21.2
helm pull instana/beeinstana-operator --version=v1.40.0

