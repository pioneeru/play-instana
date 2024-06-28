#!/bin/bash

echo "Reading credentials.env..."
source ../credentials.env

### Units
echo "Deleteing unit..."
${KUBECTL} -n instana-units delete unit `${KUBECTL} -n instana-units get unit -o jsonpath='{.items[0].metadata.name}'` --wait=false
echo "Waiting for Unit pods deletion..."
${KUBECTL} -n instana-units wait --for=delete pod --all --timeout=3000s

### Core
echo "Deleteing core..."
${KUBECTL} -n instana-core delete core instana-core --wait=false
echo "Waiting for Core pods deletion..."
${KUBECTL} -n instana-core wait --for=delete pod --all --timeout=3000s

### Clickhouse
echo "Deleteing chi instana..."
${KUBECTL} -n instana-clickhouse delete chi instana --wait=false

### Beeinstana
echo "Deleteing beeinstana instance..."
${KUBECTL} -n beeinstana delete beeinstana instance --wait=false

echo "Uninstaling beeinstana operator..."
helm uninstall beeinstana -n beeinstana

### Cassandra
echo "Deleteing cassdc Cassandra..."
${KUBECTL} -n instana-cassandra delete cassdc cassandra --wait=false

### Elasticsearch
echo "Deleteing es instana..."
${KUBECTL} -n instana-elastic delete es instana --wait=false

### Postgres
echo "Deleteing pg postgres..."
${KUBECTL} -n instana-postgres delete clusters.postgresql.cnpg.io postgres --wait=false

### Kafka
echo "Deleteing k instana..."
${KUBECTL} -n instana-kafka delete k instana --wait=false

### Zookeeper
echo "Waiting for chi deletion..."
${KUBECTL} -n instana-clickhouse wait --for=delete chi instana --timeout=3000s
echo "Deleteing Zookeeper instana-zookeeper..."
${KUBECTL} -n instana-clickhouse delete zk instana-zookeeper

echo "Waiting for Zookeeper pods deletion..."
${KUBECTL} -n instana-clickhouse wait --for=delete pod -lrelease=instana-zookeeper --timeout=3000s







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
helm uninstall strimzi -n instana-kafka 

echo "Uninstaling postgres-operator..."
helm uninstall cnpg -n instana-postgres 

echo "Uninstaling clickhouse-operator..."
helm uninstall clickhouse-operator -n instana-clickhouse 

echo "Uninstaling zookeeper operator..."
helm uninstall instana -n instana-zookeeper 

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

echo "Done."
