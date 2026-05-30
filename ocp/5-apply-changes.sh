#!/bin/bash

echo "Reading credentials.env..."
source ../credentials.env
source ../artifacts-${INSTANA_PLATFORM}.env

#### CREATING DATASTORES ######

./_kafka.sh install
./_elasticsearch.sh install
./_postgres.sh install
./_cassandra.sh install
./_clickhouse.sh install

echo "Waiting for Kafka pods to be running..."
${KUBECTL} -n instana-kafka wait --for=condition=Ready=true pod -lstrimzi.io/component-type=kafka --timeout=3000s
./_beeinstana.sh install

echo "Waiting for Elasticsearch to be ready..."
${KUBECTL} -n instana-elastic wait --for=jsonpath='{.status.phase}'=Ready es instana --timeout=3000s
echo "Waiting for Elasticsearch pods to be running..."
${KUBECTL} -n instana-elastic wait --for=condition=Ready=true pod -lelasticsearch.k8s.elastic.co/cluster-name=instana --timeout=3000s
echo "Waiting for Postgres cluster to be ready..."
${KUBECTL} -n instana-postgres wait --for=condition=Ready=true cluster postgres --timeout=3000s
echo "Waiting for Cassandra pods to be running..."
${KUBECTL} -n instana-cassandra wait --for=condition=Ready=true pod -lapp.kubernetes.io/name=cassandra --timeout=3000s
echo "Waiting for Clickhouse pods to be running..."
${KUBECTL} -n instana-clickhouse wait --for=jsonpath='{.status.status}'=Completed chi instana --timeout=3000s
${KUBECTL} -n instana-clickhouse wait --for=condition=Ready=true pod -lclickhouse.altinity.com/chi=instana --timeout=3000s
echo "Waiting for Beeinstana pods to be running..."
${KUBECTL} -n beeinstana wait --for=condition=Ready=true pod -lapp.kubernetes.io/name=beeinstana --timeout=3000s

#### INSTANA BACKEND ########

./_backend.sh install

echo "Done."