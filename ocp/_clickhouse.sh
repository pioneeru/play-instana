#!/bin/bash

echo "Reading credentials.env..."
source ../credentials.env
source ../artifacts-${INSTANA_PLATFORM}.env

function clickhouse_delete_crd {
    echo "Deleting Instana CHI CRD..."
    ${KUBECTL} -n instana-clickhouse delete chi instana --wait=true
    if [[ "${INSTANA_PLATFORM}" == "s390x" ]]; then
        ### Zookeeper
        echo "Deleting Zookeeper cluster..."
        ${KUBECTL} -n instana-clickhouse delete zk instana-zookeeper --wait=true
    else
        ### Clickhouse keeper
        echo "Deleting Clickhouse cluster..."
        ${KUBECTL} -n instana-clickhouse delete chk clickhouse-keeper --wait=true
    fi
}

function clickhouse_uninstall_operator {
    echo "Uninstalling clickhouse-operator..."
    helm uninstall clickhouse-operator -n instana-clickhouse --wait

    if [[ "${INSTANA_PLATFORM}" == "s390x" ]]; then
        echo "Uninstalling zookeeper operator..."
        helm uninstall instana -n instana-zookeeper --wait
    fi
}

function clickhouse_uninstall {
    clickhouse_delete_crd
    clickhouse_uninstall_operator

    echo "Deleting instana-clickhouse namespace..."
    ${KUBECTL} delete ns instana-clickhouse

    echo "Deleting clickhouse SCC..."
    ${KUBECTL} delete scc clickhouse-scc
}

function clickhouse_install {
    echo "Upgrading or installing Clickhouse..."
    ${KUBECTL} -n instana-clickhouse apply -f ${MANIFEST_FILENAME_CLICKHOUSE_SCC}

    ${KUBECTL} create namespace instana-clickhouse
    ${KUBECTL} create serviceaccount clickhouse  -n instana-clickhouse

    ${KUBECTL} create secret docker-registry instana-registry \
    --namespace=instana-clickhouse \
    --docker-username=${INSTANA_IMAGE_REGISTRY_USERNAME} \
    --docker-password=${INSTANA_IMAGE_REGISTRY_PASSWORD} \
    --docker-server=${INSTANA_IMAGE_REGISTRY}

    helm upgrade --install clickhouse-operator \
    -n instana-clickhouse --wait \
    --set operator.image.repository=${CLICKHOUSE_OPERATOR_IMAGE_NAME} \
    --set operator.image.tag=${CLICKHOUSE_OPERATOR_IMAGE_TAG} \
    --set imagePullSecrets[0].name="instana-registry" \
    ${INSTANA_AIRGAPPED_FOLDER}/${CLICKHOUSE_HELM_CHART} 


    if [[ "${INSTANA_PLATFORM}" == "s390x" ]]; then

        echo "Installing zookeeper..."
        helm upgrade --install instana -n instana-clickhouse \
        --create-namespace --wait \
        --set image.registry=${INSTANA_IMAGE_REGISTRY} \
        --set image.repository=${ZOOKEEPER_OPERATOR_IMAGE_NAME} \
        --set image.tag=${ZOOKEEPER_OPERATOR_IMAGE_TAG} \
        --set global.imagePullSecrets={"instana-registry"} \
        ${INSTANA_AIRGAPPED_FOLDER}/${ZOOKEEPER_HELM_CHART} 

        echo "Waiting for Zookeeper operator pods to be running..."
        ${KUBECTL} -n instana-clickhouse wait --for=condition=Ready=true pod -lcomponent=zookeeper-operator --timeout=3000s
        ${KUBECTL} apply -f ${MANIFEST_FILENAME_ZOOKEEPER} -n instana-clickhouse

        echo "Waiting for Zookeeper pods to be running..."
        ${KUBECTL} wait -n instana-clickhouse --for=jsonpath='{.status.conditions[0].status}'=True zk instana-zookeeper --timeout=3000s
        # ${KUBECTL} -n instana-clickhouse wait --for=condition=Ready=true pod --all --timeout=3000s

        ${KUBECTL} -n instana-clickhouse wait --for=condition=Ready=true pod -lrelease=instana-zookeeper --timeout=3000s

    else
        ${KUBECTL} -n instana-clickhouse apply -f ${MANIFEST_FILENAME_CLICKHOUSE_KEEPER}
        echo "Waiting for Clickhouse keeper pods to be running..."
        ${KUBECTL} wait -n instana-clickhouse --for=jsonpath='{status.status}'=Completed chk clickhouse-keeper --timeout=3000s
        ${KUBECTL} -n instana-clickhouse wait --for=condition=Ready=true pod -lapp=clickhouse-keeper --timeout=3000s

        if ! ${KUBECTL} get secret chi-passwords -n instana-clickhouse &> /dev/null; then
        echo "Generating chi-passwords secret in instana-clickhouse namespace..." 
cat << EOF > clickhouse-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: chi-passwords
  namespace: instana-clickhouse
type: Opaque
stringData:
  default_password: `openssl rand -base64 8 | tr -cd 'a-zA-Z0-9' | head -c32; echo`
  clickhouseuser_password: `openssl rand -base64 8 | tr -cd 'a-zA-Z0-9' | head -c32; echo`
EOF
        ${KUBECTL} apply -f clickhouse-secret.yaml
        else
        echo "chi-passwords secret already exists in instana-clickhouse namespace." 
        fi
        ${KUBECTL} create serviceaccount clickhousekeeper -n instana-clickhouse

    fi

    echo "Giving extra 30 seconds before creating clickhouse custom resource..." 
    sleep 30
    ${KUBECTL} -n instana-clickhouse apply -f ${MANIFEST_FILENAME_CLICKHOUSE}
}

#### Install operator and apply clickhouse ######
case "$1" in
  delete|delete_crd)
      clickhouse_delete_crd $@
      ;;
  uninstall_operator)
      clickhouse_uninstall_operator $@
      ;;
  uninstall)
      clickhouse_uninstall $@
      ;;
  *|install)
      clickhouse_install $@
      ;;
esac
