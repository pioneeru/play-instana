#!/bin/bash

echo "Reading credentials.env..."
source ../credentials.env
source ../artifacts-${INSTANA_PLATFORM}.env

function postgres_uninstall {
    ### Postgres
    echo "Deleteing pg postgres..."
    ${KUBECTL} -n instana-postgres delete clusters.postgresql.cnpg.io postgres --wait=false
}

function postgres_install {
    echo "Upgrading or installing Postgres..."
    ${KUBECTL} create namespace instana-postgres
    ${KUBECTL} create secret docker-registry instana-registry --namespace=instana-postgres \
      --docker-server=${INSTANA_IMAGE_REGISTRY} \
      --docker-username=${INSTANA_IMAGE_REGISTRY_USERNAME} \
      --docker-password=${INSTANA_IMAGE_REGISTRY_PASSWORD}

    # ${KUBECTL} -n instana-postgres apply -f ${MANIFEST_FILENAME_POSTGRES_SCC}

    helm upgrade --install cnpg -n instana-postgres --wait \
      --set image.repository=${POSTGRES_OPERATOR_IMAGE_NAME} \
      --set image.tag=${POSTGRES_OPERATOR_IMAGE_TAG} \
      --set imagePullSecrets[0].name=instana-registry \
      --set containerSecurityContext.runAsUser=`${KUBECTL} get namespace instana-postgres -o jsonpath='{.metadata.annotations.openshift\.io\/sa\.scc\.uid-range}' | cut -d/ -f 1` \
      --set containerSecurityContext.runAsGroup=`${KUBECTL} get namespace instana-postgres -o jsonpath='{.metadata.annotations.openshift\.io\/sa\.scc\.uid-range}' | cut -d/ -f 1` \
      ${INSTANA_AIRGAPPED_FOLDER}/${POSTGRES_HELM_CHART}

    ${KUBECTL} -n instana-postgres apply -f ${MANIFEST_FILENAME_POSTGRES}

    if ! ${KUBECTL} get secret instanaadmin -n instana-postgres &> /dev/null; then
    echo "Generating instanaadmin secret in instana-postgres namespace..." 
cat << EOF > postgres-secret.yaml
kind: Secret
apiVersion: v1
metadata:
  name: instanaadmin
  namespace: instana-postgres
type: Opaque
stringData:
  username: instanaadmin
  password: `openssl rand -base64 24 | tr -cd 'a-zA-Z0-9' | head -c32; echo`
EOF
    ${KUBECTL} apply -f postgres-secret.yaml;
    else
      echo "instanaadmin secret already exists in instana-postgres namespace."
    fi
}
#### Install cnpg operator and apply postgres ######

case "$1" in
  *|install)
      postgres_install $@
      ;;
  uninstall)
      postgres_uninstall $@
      ;;
esac
