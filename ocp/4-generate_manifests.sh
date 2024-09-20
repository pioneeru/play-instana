#!/bin/bash

echo "Reading credentials.env"
source ../credentials.env


eval "cat <<EOF
$(<templates/zookeeper.yaml)
EOF
" > ${MANIFEST_FILENAME_ZOOKEEPER}



eval "cat <<EOF
$(<templates/kafka.yaml)
EOF
" > ${MANIFEST_FILENAME_KAFKA}

eval "cat <<EOF
$(<templates/kafka-rebalance.yaml)
EOF
" > kafka-rebalance.yaml



eval "cat <<EOF
$(<templates/elasticsearch.yaml)
EOF
" > ${MANIFEST_FILENAME_ELASTICSEARCH}



eval "cat <<EOF
$(<templates/postgresql.yaml)
EOF
" > ${MANIFEST_FILENAME_POSTGRES}



eval "cat <<EOF
$(<templates/cassandra-scc.yaml)
EOF
" > ${MANIFEST_FILENAME_CASSANDRA_SCC}

eval "cat <<EOF
$(<templates/cassandra.yaml)
EOF
" > ${MANIFEST_FILENAME_CASSANDRA}



eval "cat <<EOF
$(<templates/clickhouse-scc.yaml)
EOF
" > ${MANIFEST_FILENAME_CLICKHOUSE_SCC}

eval "cat <<EOF
$(<templates/clickhouse.yaml)
EOF
" > ${MANIFEST_FILENAME_CLICKHOUSE}




eval "cat <<EOF
$(<templates/beeinstana.yaml)
EOF
" > ${MANIFEST_FILENAME_BEEINSTANA}




eval "cat <<EOF
$(<templates/core.yaml)
EOF
" > ${MANIFEST_FILENAME_CORE}



eval "cat <<EOF
$(<templates/unit.yaml)
EOF
" > ${MANIFEST_FILENAME_UNIT}

