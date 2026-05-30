#!/bin/bash

echo "Reading credentials.env..."
source ../credentials.env

./_backend.sh uninstall

./_kafka.sh uninstall

./_beeinstana.sh uninstall
./_cassandra.sh uninstall
./_elasticsearch.sh uninstall
./_postgres.sh uninstall

./_clickhouse.sh uninstall

if [[ "${INSTANA_PLATFORM}" == "s390x" ]]; then
    echo "Waiting for Zookeeper pods deletion..."
    ${KUBECTL} -n instana-clickhouse wait --for=delete pod -lrelease=instana-zookeeper --timeout=3000s
else
    echo "Waiting for Clickhouse Keeper pods deletion..."
    ${KUBECTL} -n instana-clickhouse wait --for=delete pod -lapp=clickhouse-keeper --timeout=3000s
fi


echo "Waiting for Elasticsearch pods deletion..."
${KUBECTL} -n instana-elastic wait --for=delete pod -lelasticsearch.k8s.elastic.co/cluster-name=instana --timeout=3000s

echo "Waiting for Clickhouse pods deletion..."
${KUBECTL} -n instana-clickhouse wait --for=delete pod -lclickhouse.altinity.com/chi=instana --timeout=3000s

echo "Waiting for Postgres pods deletion..."
${KUBECTL} -n instana-postgres wait --for=delete pod -lcnpg.io/cluster=postgres --timeout=3000s

echo "Waiting for Kafka pods deletion..."
${KUBECTL} -n instana-kafka wait --for=delete pod -lstrimzi.io/cluster=instana --timeout=3000s

echo "Waiting for Cassandra pods deletion..."
${KUBECTL} -n instana-cassandra wait --for=delete pod -lapp.kubernetes.io/name=cassandra --timeout=3000s

echo "Waiting for Beeinstana pods deletion..."
${KUBECTL} -n beeinstana wait --for=delete pod -lapp.kubernetes.io/instance=instance --timeout=3000s



echo "Uninstaling elastic-operator..."
helm uninstall elastic-operator -n instana-elastic 

echo "Uninstaling cassandra-operator..."
helm uninstall cass-operator -n instana-cassandra 

echo "Uninstaling strimzi-operator..."
helm uninstall strimzi-kafka-operator -n instana-kafka 

echo "Uninstaling postgres-operator..."
helm uninstall cnpg -n instana-postgres 

echo "Uninstaling clickhouse-operator..."
helm uninstall clickhouse-operator -n instana-clickhouse 

if [[ "${INSTANA_PLATFORM}" == "s390x" ]]; then
    echo "Uninstaling zookeeper operator..."
    helm uninstall instana -n instana-zookeeper 
fi

echo "Uninstaling instana operator..."
${KUBECTL} instana operator template --namespace instana-operator --output-dir tempinstoper
${KUBECTL} delete -f tempinstoper
rm -rf tempinstoper


echo "Deleting instana-units namespace..."
${KUBECTL} delete ns instana-units 
echo "Deleting instana-core namespace..."
${KUBECTL} delete ns instana-core 
echo "Deleting instana-postgres namespace..."
${KUBECTL} delete ns instana-postgres 
echo "Deleting instana-elastic namespace..."
${KUBECTL} delete ns instana-elastic 
echo "Deleting instana-kafka namespace..."
${KUBECTL} delete ns instana-kafka 
echo "Deleting instana-cassandra namespace..."
${KUBECTL} delete ns instana-cassandra 
echo "Deleting instana-clickhouse namespace..."
${KUBECTL} delete ns instana-clickhouse 
echo "Deleting instana-zookeeper namespace..."
${KUBECTL} delete ns instana-zookeeper 
echo "Deleting beeinstana namespace..."
${KUBECTL} delete ns beeinstana 
echo "Deleting instana-operator namespace..."
${KUBECTL} delete ns instana-operator 

echo "Deleting SCC..."
${KUBECTL} delete scc cassandra-scc
${KUBECTL} delete scc clickhouse-scc

echo "Done."
