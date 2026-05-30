#!/bin/bash

echo "Reading credentials.env..."
source ../credentials.env
source ../artifacts-${INSTANA_PLATFORM}.env

function cassandra_uninstall {
    echo "Deleting cassdc Cassandra..."
    ${KUBECTL} -n instana-cassandra delete cassdc cassandra --wait=false
}

function cassandra_install {
    echo "Upgrading or installing Cassandra..."
    ${KUBECTL} -n instana-cassandra apply -f ${MANIFEST_FILENAME_CASSANDRA_SCC}

    ${KUBECTL} create namespace instana-cassandra
    ${KUBECTL} create serviceaccount cassandra -n instana-cassandra

    ${KUBECTL} create secret docker-registry instana-registry --namespace=instana-cassandra \
      --docker-server=${INSTANA_IMAGE_REGISTRY} \
      --docker-username=${INSTANA_IMAGE_REGISTRY_USERNAME} \
      --docker-password=${INSTANA_IMAGE_REGISTRY_PASSWORD}

    if [[ "${CASSANDRA_OPERATOR_IMAGE_TAG}" == "1.26.*" ]]; then
        echo "Installing cassandra ppc64le..."
        helm upgrade --install cass-operator -n instana-cassandra --wait \
          --set securityContext.runAsGroup=`${KUBECTL} get namespace instana-cassandra -o jsonpath='{.metadata.annotations.openshift\.io\/sa\.scc\.uid-range}' | cut -d/ -f 1` \
          --set securityContext.runAsUser=`${KUBECTL} get namespace instana-cassandra -o jsonpath='{.metadata.annotations.openshift\.io\/sa\.scc\.uid-range}' | cut -d/ -f 1` \
          --set securityContext.allowPrivilegeEscalation=false \
          --set securityContext.capabilities.drop[0]="ALL" \
          --set securityContext.seccompProfile.type="RuntimeDefault" \
          --set image.registry=${CASSANDRA_IMAGE_REGISTRY} \
          --set image.repository=${CASSANDRA_OPERATOR_IMAGE_NAME} \
          --set image.tag=${CASSANDRA_OPERATOR_IMAGE_TAG} \
          --set imagePullSecrets[0].name=instana-registry \
          --set appVersion=${CASSANDRA_OPERATOR_APP_VERSION} \
          --set imageConfig.systemLogger=${CASSANDRA_SYSTEMLOGGER_IMAGE_NAME} \
          --set imageConfig.k8ssandraClient=${CASSANDRA_K8SSANDRACLIENT_IMAGE_NAME} \
          ${INSTANA_AIRGAPPED_FOLDER}/${CASSANDRA_HELM_CHART}
    else
        echo "Installing cassandra..."
        helm upgrade --install cass-operator -n instana-cassandra --wait \
          --set securityContext.runAsGroup=`${KUBECTL} get namespace instana-cassandra -o jsonpath='{.metadata.annotations.openshift\.io\/sa\.scc\.uid-range}' | cut -d/ -f 1` \
          --set securityContext.runAsUser=`${KUBECTL} get namespace instana-cassandra -o jsonpath='{.metadata.annotations.openshift\.io\/sa\.scc\.uid-range}' | cut -d/ -f 1` \
          --set securityContext.allowPrivilegeEscalation=false \
          --set securityContext.capabilities.drop[0]="ALL" \
          --set securityContext.seccompProfile.type="RuntimeDefault" \
          --set image.registry=${CASSANDRA_IMAGE_REGISTRY} \
          --set image.repository=${CASSANDRA_OPERATOR_IMAGE_NAME} \
          --set image.tag=${CASSANDRA_OPERATOR_IMAGE_TAG} \
          --set imagePullSecrets[0].name=instana-registry \
          --set appVersion=${CASSANDRA_OPERATOR_APP_VERSION} \
          --set global.imageConfig.defaults.registry=${CASSANDRA_IMAGE_REGISTRY}  \
          --set global.imageConfig.images.k8ssandra-client.repository=${CASSANDRA_IMAGE_REPOSITORY} \
          --set global.imageConfig.images.k8ssandra-client.name=k8ssandra-client \
          --set global.imageConfig.images.k8ssandra-client.tag=${CASSANDRA_K8SSANDRACLIENT_IMAGE_TAG} \
          ${INSTANA_AIRGAPPED_FOLDER}/${CASSANDRA_HELM_CHART}
    fi

    ${KUBECTL} -n instana-cassandra apply -f ${MANIFEST_FILENAME_CASSANDRA} 
}

#### Install Cassandra operator and apply cassandra ######

case "$1" in
  uninstall)
      cassandra_uninstall $@
      ;;
  *|install)
      cassandra_install $@
      ;;
esac
