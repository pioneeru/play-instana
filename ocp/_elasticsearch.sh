#!/bin/bash

echo "Reading credentials.env..."
source ../credentials.env
source ../artifacts-${INSTANA_PLATFORM}.env

function elasticsearch_delete_crd {
    echo "Deleting Instana Elasticsearch CRD..."
    ${KUBECTL} -n instana-elastic delete es instana --wait=true
}

function elasticsearch_uninstall_operator {
    echo "Uninstalling elastic-operator..."
    helm uninstall elastic-operator -n instana-elastic -wait
}

function elasticsearch_uninstall {
    elasticsearch_delete_crd
    elasticsearch_uninstall_operator

    echo "Deleting instana-elasticsearch namespace..."
    ${KUBECTL} delete ns instana-elasticsearch     
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
  delete|delete_crd)
      elasticsearch_delete_crd $@
      ;;
  uninstall_operator)
      elasticsearch_uninstall_operator $@
      ;;
  uninstall)
      elasticsearch_uninstall $@
      ;;
  *|install)
      elasticsearch_install $@
      ;;
esac
