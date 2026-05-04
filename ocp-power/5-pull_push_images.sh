#!/bin/bash

echo "Reading credentials.env"
source ../credentials.env
source ../artefacts.env

# INSTANA_IMAGE_REGISTRY=${INSTANA_IMAGE_REGISTRY}/instana
# INSTANA_IMAGE_REGISTRY_USERNAME=user
# INSTANA_IMAGE_REGISTRY_PASSWORD=pass

### The env vars defined in credentials.env
# INSTANA_OPERATOR_IMAGE_NAME=infrastructure/instana-enterprise-operator
# INSTANA_BACKEND_IMAGE_REPOSITORY=backend
# INSTANA_DATASTORE_IMAGE_REPOSITORY=datastore
# INSTANA_DATASTORE_OPERATOR_IMAGE_REPOSITORY=operator
# INSTANA_K8S_IMAGE_REPOSITORY=k8s

podman login artifact-public.instana.io -u _ -p ${DOWNLOAD_KEY}
podman login ${INSTANA_IMAGE_REGISTRY} -u ${INSTANA_IMAGE_REGISTRY_USERNAME} -p ${INSTANA_IMAGE_REGISTRY_USERNAME}

function copy_image {

    SOURCE_IMAGE=$1
    TARGET_IMAGE=$2

    echo "Image: ${SOURCE_IMAGE} -> ${TARGET_IMAGE}" 
    podman pull ${SOURCE_IMAGE}
    podman tag ${SOURCE_IMAGE} ${TARGET_IMAGE}
    podman push ${TARGET_IMAGE}

}

### Copy Cassandra images
copy_image "artifact-public.instana.io/self-hosted-images/3rd-party/operator/cass-operator:${CASSANDRA_OPERATOR_IMAGE_TAG}" \
        "${INSTANA_IMAGE_REGISTRY}/${INSTANA_DATASTORE_OPERATOR_IMAGE_REPOSITORY}/cass-operator:${CASSANDRA_OPERATOR_IMAGE_TAG}"

copy_image "artifact-public.instana.io/self-hosted-images/3rd-party/datastore/system-logger:${CASSANDRA_SYSTEMLOGGER_IMAGE_TAG}" \
        "${INSTANA_IMAGE_REGISTRY}/${INSTANA_DATASTORE_IMAGE_REPOSITORY}/system-logger:${CASSANDRA_SYSTEMLOGGER_IMAGE_TAG}"

copy_image "artifact-public.instana.io/self-hosted-images/3rd-party/datastore/k8ssandra-client:${CASSANDRA_K8SSANDRACLIENT_IMAGE_TAG}" \
        "${INSTANA_IMAGE_REGISTRY}/${INSTANA_DATASTORE_IMAGE_REPOSITORY}/k8ssandra-client:${CASSANDRA_K8SSANDRACLIENT_IMAGE_TAG}"

copy_image "artifact-public.instana.io/self-hosted-images/3rd-party/datastore/cassandra:${CASSANDRA_SERVER_IMAGE_TAG}" \
        "${INSTANA_IMAGE_REGISTRY}/${INSTANA_DATASTORE_IMAGE_REPOSITORY}/cassandra:${CASSANDRA_SERVER_IMAGE_TAG}"

### Copy Clickhouse images
copy_image "artifact-public.instana.io/clickhouse-operator:${CLICKHOUSE_OPERATOR_IMAGE_TAG}" \
        "${INSTANA_IMAGE_REGISTRY}/clickhouse-operator:${CLICKHOUSE_OPERATOR_IMAGE_TAG}"
copy_image "artifact-public.instana.io/clickhouse-openssl:${CLICKHOUSE_IMAGE_TAG}" \
        "${INSTANA_IMAGE_REGISTRY}/clickhouse-openssl:${CLICKHOUSE_IMAGE_TAG}"

### Copy Elasticsearch images
copy_image "artifact-public.instana.io/self-hosted-images/3rd-party/operator/elasticsearch:${ELASTIC_OPERATOR_IMAGE_TAG}" \
        "${INSTANA_IMAGE_REGISTRY}/${INSTANA_DATASTORE_OPERATOR_IMAGE_REPOSITORY}/elasticsearch:${ELASTIC_OPERATOR_IMAGE_TAG}"
copy_image "artifact-public.instana.io/self-hosted-images/3rd-party/datastore/elasticsearch:${ELASTIC_IMAGE_TAG}" \
        "${INSTANA_IMAGE_REGISTRY}/${INSTANA_DATASTORE_IMAGE_REPOSITORY}/elasticsearch:${ELASTIC_IMAGE_TAG}"

### Copy Kafka images
copy_image "artifact-public.instana.io/self-hosted-images/3rd-party/operator/strimzi:${KAFKA_OPERATOR_IMAGE_TAG}" \
        "${INSTANA_IMAGE_REGISTRY}/${INSTANA_DATASTORE_OPERATOR_IMAGE_REPOSITORY}/strimzi:${KAFKA_OPERATOR_IMAGE_TAG}"
copy_image "artifact-public.instana.io/self-hosted-images/3rd-party/datastore/kafka:${KAFKA_IMAGE_TAG}" \
        "${INSTANA_IMAGE_REGISTRY}/${INSTANA_DATASTORE_IMAGE_REPOSITORY}/kafka:${KAFKA_IMAGE_TAG}"

### Copy Postgres images
copy_image "artifact-public.instana.io/self-hosted-images/3rd-party/operator/cloudnative-pg:${POSTGRES_OPERATOR_IMAGE_TAG}" \
        "${INSTANA_IMAGE_REGISTRY}/${INSTANA_DATASTORE_OPERATOR_IMAGE_REPOSITORY}/cloudnative-pg:${POSTGRES_OPERATOR_IMAGE_TAG}"
copy_image "artifact-public.instana.io/self-hosted-images/3rd-party/datastore/cnpg-containers:${POSTGRES_IMAGE_TAG}" \
        "${INSTANA_IMAGE_REGISTRY}/${INSTANA_DATASTORE_IMAGE_REPOSITORY}/cnpg-containers:${POSTGRES_IMAGE_TAG}"

### Copy Beeinstana images
copy_image "artifact-public.instana.io/beeinstana/operator:${BEEINSTANA_OPERATOR_IMAGE_TAG}" \
        "${INSTANA_IMAGE_REGISTRY}/beeinstana/operator:${BEEINSTANA_OPERATOR_IMAGE_TAG}"
copy_image "artifact-public.instana.io/beeinstana/aggregator:${BEEINSTANA_AGGREGATOR_IMAGE_TAG}" \
        "${INSTANA_IMAGE_REGISTRY}/beeinstana/aggregator:${BEEINSTANA_AGGREGATOR_IMAGE_TAG}"
copy_image "artifact-public.instana.io/beeinstana/monconfig:${BEEINSTANA_MONCONFIG_IMAGE_TAG}" \
        "${INSTANA_IMAGE_REGISTRY}/beeinstana/monconfig:${BEEINSTANA_MONCONFIG_IMAGE_TAG}"
copy_image "artifact-public.instana.io/beeinstana/ingestor:${BEEINSTANA_INGESTOR_IMAGE_TAG}" \
        "${INSTANA_IMAGE_REGISTRY}/beeinstana/ingestor:${BEEINSTANA_INGESTOR_IMAGE_TAG}"

### Copy Instana backend images
#i=0
instana_image_pattern="(artifact-public.instana.io)/([-a-z0-9/]+)/([-a-z0-9]+):(.*)"
while IFS= read -r line; do
#    ((i+=1))
    if [[ "$line" =~ $instana_image_pattern ]]; then
        TEMP_IMAGE_REGISTRY=${BASH_REMATCH[1]}
        TEMP_IMAGE_REPOSITORY=${BASH_REMATCH[2]}
        TEMP_IMAGE_NAME=${BASH_REMATCH[3]}
        TEMP_IMAGE_TAG=${BASH_REMATCH[4]}

        copy_image "${TEMP_IMAGE_REGISTRY}/${TEMP_IMAGE_REPOSITORY}/${TEMP_IMAGE_NAME}:${TEMP_IMAGE_TAG}" \
                   "${INSTANA_IMAGE_REGISTRY}/${TEMP_IMAGE_REPOSITORY}/${TEMP_IMAGE_NAME}:${TEMP_IMAGE_TAG}"
    fi

done <<< `${KUBECTL} instana versions list-images -i ${INSTANA_CORE_IMAGE_TAG} -d ${DOWNLOAD_KEY}`

#echo "total: $i"

