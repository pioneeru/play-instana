#!/bin/bash

echo "Reading credentials.env..."
source ../credentials.env
source ../artifacts-${INSTANA_PLATFORM}.env


function beeinstana_delete_crd {
    echo "Deleting Beeinstana CRD..."
    ${KUBECTL} -n beeinstana delete beeinstana instance --wait=true
}

function beeinstana_uninstall_operator {
    echo "Uninstalling beeinstana operator..."
    helm uninstall beeinstana -n beeinstana-wait
}

function beeinstana_uninstall {
    beeinstana_delete_crd
    beeinstana_uninstall_operator

    echo "Deleting instana-beeinstana namespace..."
    ${KUBECTL} delete ns instana-beeinstana     
}

function beeinstana_install {
    echo "Waiting for Kafka pods to be running..."
    ${KUBECTL} -n instana-kafka wait --for=condition=Ready=true pod -lstrimzi.io/component-type=kafka --timeout=3000s

    echo "Upgrading or installing Beeinstana..."
    ${KUBECTL} create namespace beeinstana
    ${KUBECTL} create secret docker-registry instana-registry --namespace=beeinstana \
      --docker-server=${INSTANA_IMAGE_REGISTRY} \
      --docker-username=${INSTANA_IMAGE_REGISTRY_USERNAME} \
      --docker-password=${INSTANA_IMAGE_REGISTRY_PASSWORD}
    # for k8s and OCP 4.10:
    #helm install beeinstana instana/beeinstana-operator --namespace=beeinstana
    # For a cluster on Red Hat OpenShift 4.11 and later:
    helm upgrade --install beeinstana --namespace=beeinstana --wait \
      --set operator.securityContext.seccompProfile.type=RuntimeDefault \
      --set image.registry=${INSTANA_IMAGE_REGISTRY} \
      --set image.repository=${BEEINSTANA_OPERATOR_IMAGE_NAME} \
      --set image.tag=${BEEINSTANA_OPERATOR_IMAGE_TAG} \
      ${INSTANA_AIRGAPPED_FOLDER}/${BEEINSTANA_HELM_CHART}

    while ! ${KUBECTL} get secret strimzi-kafka-user -n instana-kafka; do echo "Waiting for strimzi-kafka-user secret in instana-kafka. CTRL-C to exit."; sleep 10; done

    if ${KUBECTL} get secret beeinstana-kafka-creds -n beeinstana  &> /dev/null; then
        ${KUBECTL} delete secret beeinstana-kafka-creds -n beeinstana
    fi
    ${KUBECTL} create secret generic beeinstana-kafka-creds -n beeinstana \
      --from-literal=username=strimzi-kafka-user \
      --from-literal=password=`${KUBECTL} get secret strimzi-kafka-user  -n instana-kafka --template='{{index .data.password | base64decode}}'`

    if ! ${KUBECTL} get secret beeinstana-admin-creds -n beeinstana &> /dev/null; then
        echo "Generating beeinstana-admin-creds secret in instana-beeinstana namespace..." 
        ${KUBECTL} create secret generic beeinstana-admin-creds -n beeinstana \
          --from-literal=username=beeinstana-user \
          --from-literal=password=`openssl rand -base64 24 | tr -cd 'a-zA-Z0-9' | head -c32; echo`
    else
        echo "beeinstana-admin-creds secret already exists in instana-beeinstana namespace." 
    fi

    ${KUBECTL} -n beeinstana apply -f ${MANIFEST_FILENAME_BEEINSTANA}

    ${KUBECTL} -n beeinstana patch beeinstana/instance --type=json --patch '
    [
      { 
        "op": "replace",
        "path": "/spec/fsGroup",
        "value": '`${KUBECTL} get namespace beeinstana -o jsonpath='{.metadata.annotations.openshift\.io\/sa\.scc\.uid-range}' | cut -d/ -f 1`'
      }
    ]'
}


#### Install beeinstana operator and apply beeinstana ######
case "$1" in
  delete|delete_crd)
      beeinstana_delete_crd $@
      ;;
  uninstall_operator)
      beeinstana_uninstall_operator $@
      ;;
  uninstall)
      beeinstana_uninstall $@
      ;;
  *|install)
      beeinstana_install $@
      ;;
esac
