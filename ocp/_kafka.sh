#!/bin/bash

echo "Reading credentials.env..."
source ../credentials.env
source ../artifacts-${INSTANA_PLATFORM}.env


function kafka_uninstall {
    echo "Deleteing Instana Kafka..."
    ${KUBECTL} -n instana-kafka delete k instana --wait=false
    ${KUBECTL} -n instana-kafka delete knp controller kafka --wait=false
}

function kafka_install {
    echo "Checking Kafka prerequisites..."
    ${KUBECTL} create namespace instana-kafka
    ${KUBECTL} create secret docker-registry instana-registry \
      --namespace=instana-kafka \
      --docker-username=${INSTANA_IMAGE_REGISTRY_USERNAME} \
      --docker-password=${INSTANA_IMAGE_REGISTRY_PASSWORD} \
      --docker-server=${INSTANA_IMAGE_REGISTRY}

    echo "Upgrading or installing strimzi..."
    helm upgrade --install strimzi-kafka-operator -n instana-kafka --wait \
      --set "securityContext.seccompProfile.type=RuntimeDefault" \
      --version ${KAFKA_HELM_CHART_VERSION} \
      --set image.registry=${KAFKA_IMAGE_REGISTRY} \
      --set image.repository=${KAFKA_OPERATOR_IMAGE_REPOSITORY} \
      --set image.name=${KAFKA_OPERATOR_IMAGE_NAME} \
      --set image.tag=${KAFKA_OPERATOR_IMAGE_TAG} \
      --set image.imagePullSecrets[0].name="instana-registry" \
      --set kafka.image.registry=${KAFKA_IMAGE_REGISTRY} \
      --set kafka.image.repository=${KAFKA_IMAGE_REPOSITORY} \
      --set kafka.image.name=${KAFKA_IMAGE_NAME} \
      --set kafka.image.tag=${KAFKA_IMAGE_TAG} \
      ${INSTANA_AIRGAPPED_FOLDER}/${KAFKA_HELM_CHART} 


    ${KUBECTL} apply -f ${MANIFEST_FILENAME_KAFKA_NPCPNTROLLER} -n instana-kafka
    ${KUBECTL} apply -f ${MANIFEST_FILENAME_KAFKA_NPBROKER} -n instana-kafka
    ${KUBECTL} apply -f ${MANIFEST_FILENAME_KAFKA_USERS} -n instana-kafka
    ${KUBECTL} apply -f ${MANIFEST_FILENAME_KAFKA} -n instana-kafka
}


#### Install strimzi and apply kafka ######

case "$1" in
  uninstall)
      kafka_uninstall $@
      ;;
  *|install)
      kafka_install $@
      ;;
esac
