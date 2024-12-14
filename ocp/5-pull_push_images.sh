#!/bin/bash

echo "Reading credentials.env"
source ../credentials.env
source ../artefacts.env

# INSTANA_IMAGE_REGISTRY=${INSTANA_IMAGE_REGISTRY}/instana
# INSTANA_IMAGE_REGISTRY_USERNAME=user
# INSTANA_IMAGE_REGISTRY_PASSWORD=pass

# INSTANA_OPERATOR_IMAGE_NAME=infrastructure/instana-enterprise-operator
# INSTANA_BACKEND_IMAGE_REPOSITORY=backend
# INSTANA_DATASTORE_IMAGE_REPOSITORY=datastore
# INSTANA_DATASTORE_OPERATOR_IMAGE_REPOSITORY=operator
# INSTANA_K8S_IMAGE_REPOSITORY=k8s

podman login artifact-public.instana.io -u _ -p ${DOWNLOAD_KEY}
podman login ${INSTANA_IMAGE_REGISTRY} -u ${INSTANA_IMAGE_REGISTRY_USERNAME} -p ${INSTANA_IMAGE_REGISTRY_USERNAME}

## Cassandra
podman pull artifact-public.instana.io/self-hosted-images/3rd-party/operator/cass-operator:${CASSANDRA_OPERATOR_IMAGE_TAG}
podman pull artifact-public.instana.io/self-hosted-images/3rd-party/datastore/system-logger:${CASSANDRA_SYSTEMLOGGER_IMAGE_TAG}
podman pull artifact-public.instana.io/self-hosted-images/3rd-party/datastore/k8ssandra-client:${CASSANDRA_K8SSANDRACLIENT_IMAGE_TAG}
podman pull artifact-public.instana.io/self-hosted-images/3rd-party/datastore/cassandra:${CASSANDRA_SERVER_IMAGE_TAG}

podman tag artifact-public.instana.io/self-hosted-images/3rd-party/operator/cass-operator:${CASSANDRA_OPERATOR_IMAGE_TAG} ${INSTANA_IMAGE_REGISTRY}/${INSTANA_DATASTORE_OPERATOR_IMAGE_REPOSITORY}/cass-operator:${CASSANDRA_OPERATOR_IMAGE_TAG}
podman tag artifact-public.instana.io/self-hosted-images/3rd-party/datastore/system-logger:${CASSANDRA_SYSTEMLOGGER_IMAGE_TAG} ${INSTANA_IMAGE_REGISTRY}/${INSTANA_DATASTORE_IMAGE_REPOSITORY}/system-logger:${CASSANDRA_SYSTEMLOGGER_IMAGE_TAG}
podman tag artifact-public.instana.io/self-hosted-images/3rd-party/datastore/k8ssandra-client:${CASSANDRA_K8SSANDRACLIENT_IMAGE_TAG} ${INSTANA_IMAGE_REGISTRY}/${INSTANA_DATASTORE_IMAGE_REPOSITORY}/k8ssandra-client:${CASSANDRA_K8SSANDRACLIENT_IMAGE_TAG}
podman tag artifact-public.instana.io/self-hosted-images/3rd-party/datastore/cassandra:${CASSANDRA_SERVER_IMAGE_TAG} ${INSTANA_IMAGE_REGISTRY}/${INSTANA_DATASTORE_IMAGE_REPOSITORY}/cassandra:${CASSANDRA_SERVER_IMAGE_TAG}

podman push ${INSTANA_IMAGE_REGISTRY}/${INSTANA_DATASTORE_OPERATOR_IMAGE_REPOSITORY}/cass-operator:${CASSANDRA_OPERATOR_IMAGE_TAG}
podman push ${INSTANA_IMAGE_REGISTRY}/${INSTANA_DATASTORE_IMAGE_REPOSITORY}/system-logger:${CASSANDRA_SYSTEMLOGGER_IMAGE_TAG}
podman push ${INSTANA_IMAGE_REGISTRY}/${INSTANA_DATASTORE_IMAGE_REPOSITORY}/k8ssandra-client:${CASSANDRA_K8SSANDRACLIENT_IMAGE_TAG}
podman push ${INSTANA_IMAGE_REGISTRY}/${INSTANA_DATASTORE_IMAGE_REPOSITORY}/cassandra:${CASSANDRA_SERVER_IMAGE_TAG}

## Zookeeper
podman pull artifact-public.instana.io/self-hosted-images/3rd-party/operator/zookeeper:${ZOOKEEPER_OPERATOR_IMAGE_TAG}
podman pull artifact-public.instana.io/self-hosted-images/3rd-party/datastore/zookeeper:${ZOOKEEPER_TAG_NAME}
podman pull artifact-public.instana.io/self-hosted-images/k8s/kubectl:${ZOOKEEPER_K8S_IMAGE_TAG}

podman tag artifact-public.instana.io/self-hosted-images/3rd-party/operator/zookeeper:${ZOOKEEPER_OPERATOR_IMAGE_TAG} ${INSTANA_IMAGE_REGISTRY}/${INSTANA_DATASTORE_OPERATOR_IMAGE_REPOSITORY}/zookeeper:${ZOOKEEPER_OPERATOR_IMAGE_TAG}
podman tag artifact-public.instana.io/self-hosted-images/3rd-party/datastore/zookeeper:${ZOOKEEPER_TAG_NAME} ${INSTANA_IMAGE_REGISTRY}/${INSTANA_DATASTORE_IMAGE_REPOSITORY}/zookeeper:${ZOOKEEPER_TAG_NAME}
podman tag artifact-public.instana.io/self-hosted-images/k8s/kubectl:${ZOOKEEPER_K8S_IMAGE_TAG} ${INSTANA_IMAGE_REGISTRY}/${INSTANA_K8S_IMAGE_REPOSITORY}/kubectl:${ZOOKEEPER_K8S_IMAGE_TAG}

podman push ${INSTANA_IMAGE_REGISTRY}/${INSTANA_DATASTORE_OPERATOR_IMAGE_REPOSITORY}/zookeeper:${ZOOKEEPER_OPERATOR_IMAGE_TAG}
podman push ${INSTANA_IMAGE_REGISTRY}/${INSTANA_DATASTORE_IMAGE_REPOSITORY}/zookeeper:${ZOOKEEPER_TAG_NAME}
podman push ${INSTANA_IMAGE_REGISTRY}/${INSTANA_K8S_IMAGE_REPOSITORY}/kubectl:${ZOOKEEPER_K8S_IMAGE_TAG}

## Clickhouse
podman pull artifact-public.instana.io/clickhouse-operator:${CLICKHOUSE_OPERATOR_IMAGE_TAG}
podman pull artifact-public.instana.io/clickhouse-openssl:${CLICKHOUSE_IMAGE_TAG}

podman tag artifact-public.instana.io/clickhouse-operator:${CLICKHOUSE_OPERATOR_IMAGE_TAG} ${INSTANA_IMAGE_REGISTRY}/clickhouse-operator:${CLICKHOUSE_OPERATOR_IMAGE_TAG}
podman tag artifact-public.instana.io/clickhouse-openssl:${CLICKHOUSE_IMAGE_TAG} ${INSTANA_IMAGE_REGISTRY}/clickhouse-openssl:${CLICKHOUSE_IMAGE_TAG}

podman push ${INSTANA_IMAGE_REGISTRY}/clickhouse-operator:${CLICKHOUSE_OPERATOR_IMAGE_TAG}
podman push ${INSTANA_IMAGE_REGISTRY}/clickhouse-openssl:${CLICKHOUSE_IMAGE_TAG}

## Elasticsearch
podman pull artifact-public.instana.io/self-hosted-images/3rd-party/operator/elasticsearch:${ELASTIC_OPERATOR_IMAGE_TAG}
podman pull artifact-public.instana.io/self-hosted-images/3rd-party/datastore/elasticsearch:${ELASTIC_IMAGE_TAG}

podman tag artifact-public.instana.io/self-hosted-images/3rd-party/operator/elasticsearch:${ELASTIC_OPERATOR_IMAGE_TAG} ${INSTANA_IMAGE_REGISTRY}/${INSTANA_DATASTORE_OPERATOR_IMAGE_REPOSITORY}/elasticsearch:${ELASTIC_OPERATOR_IMAGE_TAG}
podman tag artifact-public.instana.io/self-hosted-images/3rd-party/datastore/elasticsearch:${ELASTIC_IMAGE_TAG} ${INSTANA_IMAGE_REGISTRY}/${INSTANA_DATASTORE_IMAGE_REPOSITORY}/elasticsearch:${ELASTIC_IMAGE_TAG}

podman push ${INSTANA_IMAGE_REGISTRY}/${INSTANA_DATASTORE_OPERATOR_IMAGE_REPOSITORY}/elasticsearch:${ELASTIC_OPERATOR_IMAGE_TAG}
podman push ${INSTANA_IMAGE_REGISTRY}/${INSTANA_DATASTORE_IMAGE_REPOSITORY}/elasticsearch:${ELASTIC_IMAGE_TAG}

## Kafka
podman pull artifact-public.instana.io/self-hosted-images/3rd-party/operator/strimzi:${KAFKA_OPERATOR_IMAGE_TAG}
podman pull artifact-public.instana.io/self-hosted-images/3rd-party/datastore/kafka:${KAFKA_IMAGE_TAG}

podman tag artifact-public.instana.io/self-hosted-images/3rd-party/operator/strimzi:${KAFKA_OPERATOR_IMAGE_TAG} ${INSTANA_IMAGE_REGISTRY}/${INSTANA_DATASTORE_OPERATOR_IMAGE_REPOSITORY}/strimzi:${KAFKA_OPERATOR_IMAGE_TAG}
podman tag artifact-public.instana.io/self-hosted-images/3rd-party/datastore/kafka:${KAFKA_IMAGE_TAG} ${INSTANA_IMAGE_REGISTRY}/${INSTANA_DATASTORE_IMAGE_REPOSITORY}/kafka:${KAFKA_IMAGE_TAG}

podman push ${INSTANA_IMAGE_REGISTRY}/${INSTANA_DATASTORE_OPERATOR_IMAGE_REPOSITORY}/strimzi:${KAFKA_OPERATOR_IMAGE_TAG}
podman push ${INSTANA_IMAGE_REGISTRY}/${INSTANA_DATASTORE_IMAGE_REPOSITORY}/kafka:${KAFKA_IMAGE_TAG}

## Postgres
podman pull artifact-public.instana.io/self-hosted-images/3rd-party/operator/cloudnative-pg:${POSTGRES_OPERATOR_IMAGE_TAG}
podman pull artifact-public.instana.io/self-hosted-images/3rd-party/datastore/cnpg-containers:${POSTGRES_IMAGE_TAG}

podman tag artifact-public.instana.io/self-hosted-images/3rd-party/operator/cloudnative-pg:${POSTGRES_OPERATOR_IMAGE_TAG} ${INSTANA_IMAGE_REGISTRY}/${INSTANA_DATASTORE_OPERATOR_IMAGE_REPOSITORY}/cloudnative-pg:${POSTGRES_OPERATOR_IMAGE_TAG}
podman tag artifact-public.instana.io/self-hosted-images/3rd-party/datastore/cnpg-containers:${POSTGRES_IMAGE_TAG} ${INSTANA_IMAGE_REGISTRY}/${INSTANA_DATASTORE_IMAGE_REPOSITORY}/cnpg-containers:${POSTGRES_IMAGE_TAG}

podman push ${INSTANA_IMAGE_REGISTRY}/${INSTANA_DATASTORE_OPERATOR_IMAGE_REPOSITORY}/cloudnative-pg:${POSTGRES_OPERATOR_IMAGE_TAG}
podman push ${INSTANA_IMAGE_REGISTRY}/${INSTANA_DATASTORE_IMAGE_REPOSITORY}/cnpg-containers:${POSTGRES_IMAGE_TAG}

## Beeinstana
podman pull --platform linux/amd64 artifact-public.instana.io/beeinstana/operator:${BEEINSTANA_OPERATOR_IMAGE_TAG}
podman pull --platform linux/amd64 artifact-public.instana.io/beeinstana/aggregator:${BEEINSTANA_AGGREGATOR_IMAGE_TAG}
podman pull --platform linux/amd64 artifact-public.instana.io/beeinstana/monconfig:${BEEINSTANA_MONCONFIG_IMAGE_TAG}
podman pull --platform linux/amd64 artifact-public.instana.io/beeinstana/ingestor:${BEEINSTANA_INGESTOR_IMAGE_TAG}

podman tag artifact-public.instana.io/beeinstana/operator:${BEEINSTANA_OPERATOR_IMAGE_TAG} ${INSTANA_IMAGE_REGISTRY}/beeinstana/operator:${BEEINSTANA_OPERATOR_IMAGE_TAG}
podman tag artifact-public.instana.io/beeinstana/aggregator:${BEEINSTANA_AGGREGATOR_IMAGE_TAG} ${INSTANA_IMAGE_REGISTRY}/beeinstana/aggregator:${BEEINSTANA_AGGREGATOR_IMAGE_TAG}
podman tag artifact-public.instana.io/beeinstana/monconfig:${BEEINSTANA_MONCONFIG_IMAGE_TAG} ${INSTANA_IMAGE_REGISTRY}/beeinstana/monconfig:${BEEINSTANA_MONCONFIG_IMAGE_TAG}
podman tag artifact-public.instana.io/beeinstana/ingestor:${BEEINSTANA_INGESTOR_IMAGE_TAG} ${INSTANA_IMAGE_REGISTRY}/beeinstana/ingestor:${BEEINSTANA_INGESTOR_IMAGE_TAG}

podman push ${INSTANA_IMAGE_REGISTRY}/beeinstana/operator:${BEEINSTANA_OPERATOR_IMAGE_TAG}
podman push ${INSTANA_IMAGE_REGISTRY}/beeinstana/aggregator:${BEEINSTANA_AGGREGATOR_IMAGE_TAG}
podman push ${INSTANA_IMAGE_REGISTRY}/beeinstana/monconfig:${BEEINSTANA_MONCONFIG_IMAGE_TAG}
podman push ${INSTANA_IMAGE_REGISTRY}/beeinstana/ingestor:${BEEINSTANA_INGESTOR_IMAGE_TAG}

## Instana backend
podman pull artifact-public.instana.io/backend/acceptor:${INSTANA_CORE_IMAGE_TAG}
podman pull artifact-public.instana.io/backend/accountant:${INSTANA_CORE_IMAGE_TAG}
podman pull artifact-public.instana.io/backend/action-orchestration:${INSTANA_CORE_IMAGE_TAG}
podman pull artifact-public.instana.io/backend/action-reader:${INSTANA_CORE_IMAGE_TAG}
podman pull artifact-public.instana.io/backend/action-writer:${INSTANA_CORE_IMAGE_TAG}
podman pull artifact-public.instana.io/backend/appdata-health-aggregator:${INSTANA_CORE_IMAGE_TAG}
podman pull artifact-public.instana.io/backend/appdata-health-processor:${INSTANA_CORE_IMAGE_TAG}
podman pull artifact-public.instana.io/backend/appdata-legacy-converter:${INSTANA_CORE_IMAGE_TAG}
podman pull artifact-public.instana.io/backend/appdata-live-aggregator:${INSTANA_CORE_IMAGE_TAG}
podman pull artifact-public.instana.io/backend/appdata-processor:${INSTANA_CORE_IMAGE_TAG}
podman pull artifact-public.instana.io/backend/appdata-reader:${INSTANA_CORE_IMAGE_TAG}
podman pull artifact-public.instana.io/backend/appdata-writer:${INSTANA_CORE_IMAGE_TAG}
podman pull artifact-public.instana.io/backend/bizops-reader:${INSTANA_CORE_IMAGE_TAG}
podman pull artifact-public.instana.io/backend/bizops-writer:${INSTANA_CORE_IMAGE_TAG}
podman pull artifact-public.instana.io/backend/butler:${INSTANA_CORE_IMAGE_TAG}
podman pull artifact-public.instana.io/backend/cashier-ingest:${INSTANA_CORE_IMAGE_TAG}
podman pull artifact-public.instana.io/backend/cashier-rollup:${INSTANA_CORE_IMAGE_TAG}
podman pull artifact-public.instana.io/backend/collaborations-helper:${INSTANA_CORE_IMAGE_TAG}
podman pull artifact-public.instana.io/backend/email-health-provider:${INSTANA_CORE_IMAGE_TAG}
podman pull artifact-public.instana.io/backend/eum-acceptor:${INSTANA_CORE_IMAGE_TAG}
podman pull artifact-public.instana.io/backend/eum-health-processor:${INSTANA_CORE_IMAGE_TAG}
podman pull artifact-public.instana.io/backend/eum-processor:${INSTANA_CORE_IMAGE_TAG}
podman pull artifact-public.instana.io/backend/filler:${INSTANA_CORE_IMAGE_TAG}
podman pull artifact-public.instana.io/backend/gateway:${INSTANA_CORE_GATEWAY_IMAGE_TAG}
podman pull artifact-public.instana.io/backend/groundskeeper:${INSTANA_CORE_IMAGE_TAG}
podman pull artifact-public.instana.io/backend/infra-health-processor:${INSTANA_CORE_IMAGE_TAG}
podman pull artifact-public.instana.io/backend/infra-metric-aggregator:${INSTANA_CORE_IMAGE_TAG}
podman pull artifact-public.instana.io/backend/issue-tracker:${INSTANA_CORE_IMAGE_TAG}
podman pull artifact-public.instana.io/backend/js-stack-trace-translator:${INSTANA_CORE_IMAGE_TAG}
podman pull artifact-public.instana.io/backend/log-health-processor:${INSTANA_CORE_IMAGE_TAG}
podman pull artifact-public.instana.io/backend/log-processor:${INSTANA_CORE_IMAGE_TAG}
podman pull artifact-public.instana.io/backend/log-reader:${INSTANA_CORE_IMAGE_TAG}
podman pull artifact-public.instana.io/backend/log-writer:${INSTANA_CORE_IMAGE_TAG}
podman pull artifact-public.instana.io/backend/otlp-acceptor:${INSTANA_CORE_IMAGE_TAG}
podman pull artifact-public.instana.io/backend/processor:${INSTANA_CORE_IMAGE_TAG}
podman pull artifact-public.instana.io/backend/serverless-acceptor:${INSTANA_CORE_IMAGE_TAG}
podman pull artifact-public.instana.io/backend/sli-beacons-filter:${INSTANA_CORE_IMAGE_TAG}
podman pull artifact-public.instana.io/backend/sli-calls-filter:${INSTANA_CORE_IMAGE_TAG}
podman pull artifact-public.instana.io/backend/sli-data-reader:${INSTANA_CORE_IMAGE_TAG}
podman pull artifact-public.instana.io/backend/sli-data-writer:${INSTANA_CORE_IMAGE_TAG}
podman pull artifact-public.instana.io/backend/sli-evaluator:${INSTANA_CORE_IMAGE_TAG}
podman pull artifact-public.instana.io/backend/sli-health-processor:${INSTANA_CORE_IMAGE_TAG}
podman pull artifact-public.instana.io/backend/synthetics-acceptor:${INSTANA_CORE_IMAGE_TAG}
podman pull artifact-public.instana.io/backend/synthetics-health-processor:${INSTANA_CORE_IMAGE_TAG}
podman pull artifact-public.instana.io/backend/synthetics-reader:${INSTANA_CORE_IMAGE_TAG}
podman pull artifact-public.instana.io/backend/synthetics-writer:${INSTANA_CORE_IMAGE_TAG}
podman pull artifact-public.instana.io/backend/tag-processor:${INSTANA_CORE_IMAGE_TAG}
podman pull artifact-public.instana.io/backend/tag-reader:${INSTANA_CORE_IMAGE_TAG}
podman pull artifact-public.instana.io/backend/ui-backend:${INSTANA_CORE_IMAGE_TAG}
podman pull artifact-public.instana.io/backend/ui-client:${INSTANA_CORE_IMAGE_TAG}
podman pull artifact-public.instana.io/backend/config-templates:${INSTANA_CORE_IMAGE_TAG}
podman pull artifact-public.instana.io/infrastructure/instana-enterprise-operator:${INSTANA_OPERATOR_IMAGE_TAG}

podman tag artifact-public.instana.io/backend/acceptor:${INSTANA_CORE_IMAGE_TAG} ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/acceptor:${INSTANA_CORE_IMAGE_TAG} 
podman tag artifact-public.instana.io/backend/accountant:${INSTANA_CORE_IMAGE_TAG} ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/accountant:${INSTANA_CORE_IMAGE_TAG} 
podman tag artifact-public.instana.io/backend/action-orchestration:${INSTANA_CORE_IMAGE_TAG} ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/action-orchestration:${INSTANA_CORE_IMAGE_TAG} 
podman tag artifact-public.instana.io/backend/action-reader:${INSTANA_CORE_IMAGE_TAG} ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/action-reader:${INSTANA_CORE_IMAGE_TAG} 
podman tag artifact-public.instana.io/backend/action-writer:${INSTANA_CORE_IMAGE_TAG} ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/action-writer:${INSTANA_CORE_IMAGE_TAG} 
podman tag artifact-public.instana.io/backend/appdata-health-aggregator:${INSTANA_CORE_IMAGE_TAG} ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/appdata-health-aggregator:${INSTANA_CORE_IMAGE_TAG} 
podman tag artifact-public.instana.io/backend/appdata-health-processor:${INSTANA_CORE_IMAGE_TAG} ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/appdata-health-processor:${INSTANA_CORE_IMAGE_TAG} 
podman tag artifact-public.instana.io/backend/appdata-legacy-converter:${INSTANA_CORE_IMAGE_TAG} ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/appdata-legacy-converter:${INSTANA_CORE_IMAGE_TAG} 
podman tag artifact-public.instana.io/backend/appdata-live-aggregator:${INSTANA_CORE_IMAGE_TAG} ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/appdata-live-aggregator:${INSTANA_CORE_IMAGE_TAG} 
podman tag artifact-public.instana.io/backend/appdata-processor:${INSTANA_CORE_IMAGE_TAG} ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/appdata-processor:${INSTANA_CORE_IMAGE_TAG} 
podman tag artifact-public.instana.io/backend/appdata-reader:${INSTANA_CORE_IMAGE_TAG} ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/appdata-reader:${INSTANA_CORE_IMAGE_TAG} 
podman tag artifact-public.instana.io/backend/appdata-writer:${INSTANA_CORE_IMAGE_TAG} ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/appdata-writer:${INSTANA_CORE_IMAGE_TAG} 
podman tag artifact-public.instana.io/backend/bizops-reader:${INSTANA_CORE_IMAGE_TAG} ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/bizops-reader:${INSTANA_CORE_IMAGE_TAG} 
podman tag artifact-public.instana.io/backend/bizops-writer:${INSTANA_CORE_IMAGE_TAG} ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/bizops-writer:${INSTANA_CORE_IMAGE_TAG} 
podman tag artifact-public.instana.io/backend/butler:${INSTANA_CORE_IMAGE_TAG} ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/butler:${INSTANA_CORE_IMAGE_TAG} 
podman tag artifact-public.instana.io/backend/cashier-ingest:${INSTANA_CORE_IMAGE_TAG} ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/cashier-ingest:${INSTANA_CORE_IMAGE_TAG} 
podman tag artifact-public.instana.io/backend/cashier-rollup:${INSTANA_CORE_IMAGE_TAG} ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/cashier-rollup:${INSTANA_CORE_IMAGE_TAG} 
podman tag artifact-public.instana.io/backend/collaborations-helper:${INSTANA_CORE_IMAGE_TAG} ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/collaborations-helper:${INSTANA_CORE_IMAGE_TAG} 
podman tag artifact-public.instana.io/backend/email-health-provider:${INSTANA_CORE_IMAGE_TAG} ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/email-health-provider:${INSTANA_CORE_IMAGE_TAG} 
podman tag artifact-public.instana.io/backend/eum-acceptor:${INSTANA_CORE_IMAGE_TAG} ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/eum-acceptor:${INSTANA_CORE_IMAGE_TAG} 
podman tag artifact-public.instana.io/backend/eum-health-processor:${INSTANA_CORE_IMAGE_TAG} ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/eum-health-processor:${INSTANA_CORE_IMAGE_TAG} 
podman tag artifact-public.instana.io/backend/eum-processor:${INSTANA_CORE_IMAGE_TAG} ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/eum-processor:${INSTANA_CORE_IMAGE_TAG} 
podman tag artifact-public.instana.io/backend/filler:${INSTANA_CORE_IMAGE_TAG} ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/filler:${INSTANA_CORE_IMAGE_TAG} 
podman tag artifact-public.instana.io/backend/gateway:${INSTANA_CORE_GATEWAY_IMAGE_TAG} ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/gateway:${INSTANA_CORE_GATEWAY_IMAGE_TAG} 
podman tag artifact-public.instana.io/backend/groundskeeper:${INSTANA_CORE_IMAGE_TAG} ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/groundskeeper:${INSTANA_CORE_IMAGE_TAG} 
podman tag artifact-public.instana.io/backend/infra-health-processor:${INSTANA_CORE_IMAGE_TAG} ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/infra-health-processor:${INSTANA_CORE_IMAGE_TAG} 
podman tag artifact-public.instana.io/backend/infra-metric-aggregator:${INSTANA_CORE_IMAGE_TAG} ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/infra-metric-aggregator:${INSTANA_CORE_IMAGE_TAG} 
podman tag artifact-public.instana.io/backend/issue-tracker:${INSTANA_CORE_IMAGE_TAG} ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/issue-tracker:${INSTANA_CORE_IMAGE_TAG} 
podman tag artifact-public.instana.io/backend/js-stack-trace-translator:${INSTANA_CORE_IMAGE_TAG} ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/js-stack-trace-translator:${INSTANA_CORE_IMAGE_TAG} 
podman tag artifact-public.instana.io/backend/log-health-processor:${INSTANA_CORE_IMAGE_TAG} ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/log-health-processor:${INSTANA_CORE_IMAGE_TAG} 
podman tag artifact-public.instana.io/backend/log-processor:${INSTANA_CORE_IMAGE_TAG} ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/log-processor:${INSTANA_CORE_IMAGE_TAG} 
podman tag artifact-public.instana.io/backend/log-reader:${INSTANA_CORE_IMAGE_TAG} ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/log-reader:${INSTANA_CORE_IMAGE_TAG} 
podman tag artifact-public.instana.io/backend/log-writer:${INSTANA_CORE_IMAGE_TAG} ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/log-writer:${INSTANA_CORE_IMAGE_TAG} 
podman tag artifact-public.instana.io/backend/otlp-acceptor:${INSTANA_CORE_IMAGE_TAG} ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/otlp-acceptor:${INSTANA_CORE_IMAGE_TAG} 
podman tag artifact-public.instana.io/backend/processor:${INSTANA_CORE_IMAGE_TAG} ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/processor:${INSTANA_CORE_IMAGE_TAG} 
podman tag artifact-public.instana.io/backend/serverless-acceptor:${INSTANA_CORE_IMAGE_TAG} ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/serverless-acceptor:${INSTANA_CORE_IMAGE_TAG} 
podman tag artifact-public.instana.io/backend/sli-beacons-filter:${INSTANA_CORE_IMAGE_TAG} ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/sli-beacons-filter:${INSTANA_CORE_IMAGE_TAG} 
podman tag artifact-public.instana.io/backend/sli-calls-filter:${INSTANA_CORE_IMAGE_TAG} ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/sli-calls-filter:${INSTANA_CORE_IMAGE_TAG} 
podman tag artifact-public.instana.io/backend/sli-data-reader:${INSTANA_CORE_IMAGE_TAG} ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/sli-data-reader:${INSTANA_CORE_IMAGE_TAG} 
podman tag artifact-public.instana.io/backend/sli-data-writer:${INSTANA_CORE_IMAGE_TAG} ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/sli-data-writer:${INSTANA_CORE_IMAGE_TAG} 
podman tag artifact-public.instana.io/backend/sli-evaluator:${INSTANA_CORE_IMAGE_TAG} ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/sli-evaluator:${INSTANA_CORE_IMAGE_TAG} 
podman tag artifact-public.instana.io/backend/sli-health-processor:${INSTANA_CORE_IMAGE_TAG} ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/sli-health-processor:${INSTANA_CORE_IMAGE_TAG} 
podman tag artifact-public.instana.io/backend/synthetics-acceptor:${INSTANA_CORE_IMAGE_TAG} ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/synthetics-acceptor:${INSTANA_CORE_IMAGE_TAG} 
podman tag artifact-public.instana.io/backend/synthetics-health-processor:${INSTANA_CORE_IMAGE_TAG} ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/synthetics-health-processor:${INSTANA_CORE_IMAGE_TAG} 
podman tag artifact-public.instana.io/backend/synthetics-reader:${INSTANA_CORE_IMAGE_TAG} ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/synthetics-reader:${INSTANA_CORE_IMAGE_TAG} 
podman tag artifact-public.instana.io/backend/synthetics-writer:${INSTANA_CORE_IMAGE_TAG} ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/synthetics-writer:${INSTANA_CORE_IMAGE_TAG} 
podman tag artifact-public.instana.io/backend/tag-processor:${INSTANA_CORE_IMAGE_TAG} ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/tag-processor:${INSTANA_CORE_IMAGE_TAG} 
podman tag artifact-public.instana.io/backend/tag-reader:${INSTANA_CORE_IMAGE_TAG} ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/tag-reader:${INSTANA_CORE_IMAGE_TAG} 
podman tag artifact-public.instana.io/backend/ui-backend:${INSTANA_CORE_IMAGE_TAG} ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/ui-backend:${INSTANA_CORE_IMAGE_TAG} 
podman tag artifact-public.instana.io/backend/ui-client:${INSTANA_CORE_IMAGE_TAG} ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/ui-client:${INSTANA_CORE_IMAGE_TAG} 
podman tag artifact-public.instana.io/backend/config-templates:${INSTANA_CORE_IMAGE_TAG} ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/config-templates:${INSTANA_CORE_IMAGE_TAG} 
podman tag artifact-public.instana.io/infrastructure/instana-enterprise-operator:${INSTANA_OPERATOR_IMAGE_TAG} ${INSTANA_IMAGE_REGISTRY}/${INSTANA_OPERATOR_IMAGE_NAME}:${INSTANA_OPERATOR_IMAGE_TAG} 

podman push ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/acceptor:${INSTANA_CORE_IMAGE_TAG} 
podman push ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/accountant:${INSTANA_CORE_IMAGE_TAG} 
podman push ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/action-orchestration:${INSTANA_CORE_IMAGE_TAG} 
podman push ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/action-reader:${INSTANA_CORE_IMAGE_TAG} 
podman push ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/action-writer:${INSTANA_CORE_IMAGE_TAG} 
podman push ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/appdata-health-aggregator:${INSTANA_CORE_IMAGE_TAG} 
podman push ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/appdata-health-processor:${INSTANA_CORE_IMAGE_TAG} 
podman push ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/appdata-legacy-converter:${INSTANA_CORE_IMAGE_TAG} 
podman push ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/appdata-live-aggregator:${INSTANA_CORE_IMAGE_TAG} 
podman push ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/appdata-processor:${INSTANA_CORE_IMAGE_TAG} 
podman push ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/appdata-reader:${INSTANA_CORE_IMAGE_TAG} 
podman push ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/appdata-writer:${INSTANA_CORE_IMAGE_TAG} 
podman push ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/bizops-reader:${INSTANA_CORE_IMAGE_TAG} 
podman push ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/bizops-writer:${INSTANA_CORE_IMAGE_TAG} 
podman push ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/butler:${INSTANA_CORE_IMAGE_TAG} 
podman push ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/cashier-ingest:${INSTANA_CORE_IMAGE_TAG} 
podman push ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/cashier-rollup:${INSTANA_CORE_IMAGE_TAG} 
podman push ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/collaborations-helper:${INSTANA_CORE_IMAGE_TAG} 
podman push ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/email-health-provider:${INSTANA_CORE_IMAGE_TAG} 
podman push ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/eum-acceptor:${INSTANA_CORE_IMAGE_TAG} 
podman push ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/eum-health-processor:${INSTANA_CORE_IMAGE_TAG} 
podman push ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/eum-processor:${INSTANA_CORE_IMAGE_TAG} 
podman push ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/filler:${INSTANA_CORE_IMAGE_TAG} 
podman push ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/gateway:${INSTANA_CORE_GATEWAY_IMAGE_TAG} 
podman push ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/groundskeeper:${INSTANA_CORE_IMAGE_TAG} 
podman push ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/infra-health-processor:${INSTANA_CORE_IMAGE_TAG} 
podman push ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/infra-metric-aggregator:${INSTANA_CORE_IMAGE_TAG} 
podman push ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/issue-tracker:${INSTANA_CORE_IMAGE_TAG} 
podman push ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/js-stack-trace-translator:${INSTANA_CORE_IMAGE_TAG} 
podman push ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/log-health-processor:${INSTANA_CORE_IMAGE_TAG} 
podman push ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/log-processor:${INSTANA_CORE_IMAGE_TAG} 
podman push ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/log-reader:${INSTANA_CORE_IMAGE_TAG} 
podman push ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/log-writer:${INSTANA_CORE_IMAGE_TAG} 
podman push ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/otlp-acceptor:${INSTANA_CORE_IMAGE_TAG} 
podman push ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/processor:${INSTANA_CORE_IMAGE_TAG} 
podman push ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/serverless-acceptor:${INSTANA_CORE_IMAGE_TAG} 
podman push ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/sli-beacons-filter:${INSTANA_CORE_IMAGE_TAG} 
podman push ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/sli-calls-filter:${INSTANA_CORE_IMAGE_TAG} 
podman push ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/sli-data-reader:${INSTANA_CORE_IMAGE_TAG} 
podman push ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/sli-data-writer:${INSTANA_CORE_IMAGE_TAG} 
podman push ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/sli-evaluator:${INSTANA_CORE_IMAGE_TAG} 
podman push ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/sli-health-processor:${INSTANA_CORE_IMAGE_TAG} 
podman push ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/synthetics-acceptor:${INSTANA_CORE_IMAGE_TAG} 
podman push ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/synthetics-health-processor:${INSTANA_CORE_IMAGE_TAG} 
podman push ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/synthetics-reader:${INSTANA_CORE_IMAGE_TAG} 
podman push ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/synthetics-writer:${INSTANA_CORE_IMAGE_TAG} 
podman push ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/tag-processor:${INSTANA_CORE_IMAGE_TAG} 
podman push ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/tag-reader:${INSTANA_CORE_IMAGE_TAG} 
podman push ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/ui-backend:${INSTANA_CORE_IMAGE_TAG} 
podman push ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/ui-client:${INSTANA_CORE_IMAGE_TAG} 
podman push ${INSTANA_IMAGE_REGISTRY}/${INSTANA_BACKEND_IMAGE_REPOSITORY}/config-templates:${INSTANA_CORE_IMAGE_TAG} 
podman push ${INSTANA_IMAGE_REGISTRY}/${INSTANA_OPERATOR_IMAGE_NAME}:${INSTANA_OPERATOR_IMAGE_TAG} 

