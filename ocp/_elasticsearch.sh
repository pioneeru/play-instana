#!/bin/bash

echo "Reading credentials.env..."
source ../credentials.env
source ../artifacts-${INSTANA_PLATFORM}.env

function elasticsearch_uninstall {
    echo "Deleting es instana..."
    ${KUBECTL} -n instana-elastic delete es instana --wait=false

}

function elasticsearch_install {
    echo "Upgrading or installing Elasticsearch..."
    ${KUBECTL} create namespace instana-elastic
    ${KUBECTL} create serviceaccount elasticsearch -n instana-elastic

    ${KUBECTL} create secret docker-registry instana-registry \
      --namespace=instana-elastic \
      --docker-username=${INSTANA_IMAGE_REGISTRY_USERNAME} \
      --docker-password=${INSTANA_IMAGE_REGISTRY_PASSWORD} \
      --docker-server=${INSTANA_IMAGE_REGISTRY}

    helm upgrade --install elastic-operator -n instana-elastic --wait \
      --version=${ELASTIC_HELM_CHART_VERSION} \
      --set image.repository=${ELASTIC_OPERATOR_IMAGE_NAME} \
      --set image.tag=${ELASTIC_OPERATOR_IMAGE_TAG} \
      --set imagePullSecrets[0].name="instana-registry" \
      ${INSTANA_AIRGAPPED_FOLDER}/${ELASTIC_HELM_CHART}

    ${KUBECTL} apply -f ${MANIFEST_FILENAME_ELASTICSEARCH} -n instana-elastic
}

#### Install esk-operator and apply Elasticsearch ######
case "$1" in
  uninstall)
      elasticsearch_uninstall $@
      ;;
  *|install)
      elasticsearch_install $@
      ;;
esac
