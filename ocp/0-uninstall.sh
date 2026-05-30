#!/bin/bash

echo "Reading credentials.env..."
source ../credentials.env

./_backend.sh uninstall &

./_clickhouse.sh uninstall &
./_beeinstana.sh uninstall &
./_kafka.sh uninstall &
./_cassandra.sh uninstall &
./_elasticsearch.sh uninstall &
./_postgres.sh uninstall &




echo "Waiting for Unit pods deletion..."
${KUBECTL} -n instana-units wait --for=delete pod --all --timeout=3000s

echo "Waiting for Core pods deletion..."
${KUBECTL} -n instana-core wait --for=delete pod --all --timeout=3000s


if [[ "${INSTANA_PLATFORM}" == "s390x" ]]; then
    echo "Waiting for Zookeeper pods deletion..."
    ${KUBECTL} -n instana-clickhouse wait --for=delete pod -lrelease=instana-zookeeper --timeout=3000s
else
    echo "Waiting for Clickhouse Keeper pods deletion..."
    ${KUBECTL} -n instana-clickhouse wait --for=delete pod -lapp=clickhouse-keeper --timeout=3000s
fi

echo "Waiting for Beeinstana pods deletion..."
${KUBECTL} -n beeinstana wait --for=delete pod -lapp.kubernetes.io/instance=instance --timeout=3000s

echo "Waiting for Elasticsearch pods deletion..."
${KUBECTL} -n instana-elastic wait --for=delete pod -lelasticsearch.k8s.elastic.co/cluster-name=instana --timeout=3000s

echo "Waiting for Postgres pods deletion..."
${KUBECTL} -n instana-postgres wait --for=delete pod -lcnpg.io/cluster=postgres --timeout=3000s

echo "Waiting for Kafka pods deletion..."
${KUBECTL} -n instana-kafka wait --for=delete pod -lstrimzi.io/cluster=instana --timeout=3000s

echo "Waiting for Cassandra pods deletion..."
${KUBECTL} -n instana-cassandra wait --for=delete pod -lapp.kubernetes.io/name=cassandra --timeout=3000s

echo "Waiting for Clickhouse pods deletion..."
${KUBECTL} -n instana-clickhouse wait --for=delete pod -lclickhouse.altinity.com/chi=instana --timeout=3000s


echo "Done."
