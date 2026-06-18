#!/bin/bash

echo "Reading credentials.env..."
source ../credentials.env
source ../artifacts-${INSTANA_PLATFORM}.env


function backend_delete_crd {
    ### Units
    echo "Deleteing unit..."
    ${KUBECTL} -n instana-units delete unit `${KUBECTL} -n instana-units get unit -o jsonpath='{.items[0].metadata.name}'` --wait=true

    ### Core
    echo "Deleteing core..."
    ${KUBECTL} -n instana-core delete core instana-core --wait=true

}

function backend_uninstall_operator {
    echo "Uninstaling instana operator..."
    ${KUBECTL} instana operator template --namespace instana-operator --output-dir tempinstoper
    ${KUBECTL} delete -f tempinstoper
    rm -rf tempinstoper
}

function backend_uninstall {
    backend_delete_crd
    backend_uninstall_operator
    echo "Deleting instana-units namespace..."
    ${KUBECTL} delete ns instana-units 
    echo "Deleting instana-core namespace..."
    ${KUBECTL} delete ns instana-core 
    echo "Deleting instana-operator namespace..."
    ${KUBECTL} delete ns instana-operator 
}



function backend_install {
    echo "Installing instana-operator"
    ${KUBECTL} create ns instana-operator

    ${KUBECTL} create secret docker-registry instana-registry \
        --namespace=instana-operator \
        --docker-username=${INSTANA_IMAGE_REGISTRY_USERNAME} \
        --docker-password=${INSTANA_IMAGE_REGISTRY_PASSWORD} \
        --docker-server=${INSTANA_IMAGE_REGISTRY}

cat << EOF > instana-operator-values.yaml
operator:
  extraEnv:
    - name: INSTANA_DISABLE_DB_VERSION_CHECKS
      value: "true"
  image:
    registry: ${INSTANA_IMAGE_REGISTRY}
    # repository: ${INSTANA_OPERATOR_IMAGE_NAME}
    # tag: ${INSTANA_OPERATOR_IMAGE_TAG}
webhook:
  image:
    registry: ${INSTANA_IMAGE_REGISTRY}
    # repository: ${INSTANA_WEBHOOK_IMAGE_NAME}
    # tag: ${INSTANA_OPERATOR_IMAGE_TAG}
imagePullSecrets:
  - name: instana-registry
EOF

    ${KUBECTL} instana operator --namespace=instana-operator apply --values instana-operator-values.yaml
    sleep 5
    echo "Waiting for Instana operator pods to be running..."
    ${KUBECTL} -n instana-operator wait --for=condition=Ready=true pod -lapp.kubernetes.io/name=instana --timeout=3000s

######################



#### CORE & UNITS ####

    echo "Creating namespace for Instana core and units..."

cat << EOF > namespaces.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: instana-core
  labels:
    app.kubernetes.io/name: instana-core
---
apiVersion: v1
kind: Namespace
metadata:
  name: instana-units
  labels:
    app.kubernetes.io/name: instana-units
EOF

    ${KUBECTL} apply -f namespaces.yaml

    echo "Creating secrets for Instana core and units..."
    ${KUBECTL} create secret docker-registry instana-registry \
        --namespace=instana-core \
        --docker-username=${INSTANA_IMAGE_REGISTRY_USERNAME} \
        --docker-password=${INSTANA_IMAGE_REGISTRY_PASSWORD} \
        --docker-server=${INSTANA_IMAGE_REGISTRY}

    ${KUBECTL} create secret docker-registry instana-registry \
        --namespace=instana-units \
        --docker-username=${INSTANA_IMAGE_REGISTRY_USERNAME} \
        --docker-password=${INSTANA_IMAGE_REGISTRY_PASSWORD} \
        --docker-server=${INSTANA_IMAGE_REGISTRY}

    sleep 5

    # Creating/Updating instana tls secret
    if ! ${KUBECTL} get secret instana-tls -n instana-core  &> /dev/null; then
        # Generate certificate files
        if [[ ${TLS_CERTIFICATE_GENERATE} == "YES" ]]; then
            echo "Generating SSL certificates ${TLS_CERTIFICATE_FILE}/${TLS_KEY_FILE} ..."
            openssl genrsa -out ca.key 2048
            openssl req -new -x509 -days 365 -key ca.key \
                -subj "/C=${TLS_CERTIFICATE_GENERATE_C}/ST=${TLS_CERTIFICATE_GENERATE_ST}/L=${TLS_CERTIFICATE_GENERATE_L}/O=${TLS_CERTIFICATE_GENERATE_O}/CN=${TLS_CERTIFICATE_GENERATE_CN}" -out ca.crt
            openssl req -newkey rsa:2048 -nodes -keyout ${TLS_KEY_FILE} \
                -subj "/C=${TLS_CERTIFICATE_GENERATE_C}/ST=${TLS_CERTIFICATE_GENERATE_ST}/L=S${TLS_CERTIFICATE_GENERATE_L}/O=${TLS_CERTIFICATE_GENERATE_O}/CN=*.${INSTANA_BASE_DOMAIN}" -out tls.csr
            openssl x509 -req -extfile <(printf "subjectAltName=DNS:${INSTANA_BASE_DOMAIN},DNS:${INSTANA_TENANT_DOMAIN},DNS:${INSTANA_AGENT_ACCEPTOR},DNS:${INSTANA_EUM_ACCEPTOR},DNS:${INSTANA_SYNTHETICS_ACCEPTOR},DNS:${INSTANA_SERVERLESS_ACCEPTOR},DNS:${INSTANA_OTLP_GRPC_ACCEPTOR},DNS:${INSTANA_OTLP_HTTP_ACCEPTOR}") \
                -days 365 -in tls.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out ${TLS_CERTIFICATE_FILE}
        fi
        
        echo "Creating instana-tls secrets..."
        ${KUBECTL} create secret tls instana-tls --namespace instana-core \
            --cert=${TLS_CERTIFICATE_FILE} \
            --key=${TLS_KEY_FILE}
    fi



    # Preparing instana-core config
    echo "Generating instana-core config..."

# Diffie-Hellman parameters to use (optional)
#openssl dhparam -out dhparams.pem 2048
#openssl genrsa -out key.pem -passout pass:${KEY_PEM_PASSWORD} 4096


# SAML/OIDC keys generation (optional)
# cat > internal_csr_details.txt <<-EOF
# [req]
# default_bits = 4096
# prompt = no
# default_md = sha256
# distinguished_name = dn

# [dn]
# C=US
# ST=TX
# L=Austin
# O=IBM
# OU=Instana
# emailAddress=my@email.ibm.com
# CN=${INSTANA_BASE_DOMAIN}
# EOF

    # openssl req -new -x509 -key key.pem -days 365 \
    # 	-passin pass:${KEY_PEM_PASSWORD} -out cert.pem \
    # 	-config internal_csr_details.txt

    # cat key.pem cert.pem > sp.pem


cat > core-config-base.yaml <<-EOF
# Diffie-Hellman parameters to use (Optional)
#dhParams: |
#`#sed  's/^/  /' dhparams.pem`
# The download key you received from us
repositoryPassword: ${INSTANA_IMAGE_REGISTRY_PASSWORD}
# The sales key you received from us
salesKey: ${SALES_KEY}
# Seed for creating crypto tokens. Pick a random 12 char string
tokenSecret: ${TOKEN_SECRET}
# Configuration for raw spans storage

# SAML/OIDC configuration
# serviceProviderConfig:
#   # Password for the key/cert file
#   keyPassword: ${KEY_PEM_PASSWORD}
#   # The combined key/cert file
#   pem: |
#`#sed  's/^/    /' sp.pem`
datastoreConfigs:
  beeInstanaConfig:
    user: beeinstana-user
    password: "`${KUBECTL} get secret  beeinstana-admin-creds  -n beeinstana --template='{{index .data.password | base64decode}}'`"
  kafkaConfig:
    adminUser: strimzi-kafka-user
    adminPassword: "`${KUBECTL} get secret strimzi-kafka-user  -n instana-kafka --template='{{index .data.password | base64decode}}'`"
    consumerUser: strimzi-kafka-user
    consumerPassword: "`${KUBECTL} get secret strimzi-kafka-user  -n instana-kafka --template='{{index .data.password | base64decode}}'`"
    producerUser: strimzi-kafka-user
    producerPassword: "`${KUBECTL} get secret strimzi-kafka-user  -n instana-kafka --template='{{index .data.password | base64decode}}'`"
  elasticsearchConfig:
    adminUser: elastic
    adminPassword: "`${KUBECTL} get secret instana-es-elastic-user -n instana-elastic -o go-template='{{.data.elastic | base64decode}}'`"
    user: elastic
    password: "`${KUBECTL} get secret instana-es-elastic-user -n instana-elastic -o go-template='{{.data.elastic | base64decode}}'`"
  postgresConfigs:
    - adminUser: instanaadmin
      adminPassword: "`${KUBECTL} get secret instanaadmin -n instana-postgres --template='{{index .data.password | base64decode}}'`"
      user: instanaadmin
      password: "`${KUBECTL} get secret instanaadmin -n instana-postgres --template='{{index .data.password | base64decode}}'`"
  cassandraConfigs:
    - adminUser: instana-superuser
      adminPassword: "`${KUBECTL} get secret instana-superuser -n instana-cassandra --template='{{index .data.password | base64decode}}'`"
      user: instana-superuser
      password: "`${KUBECTL} get secret instana-superuser -n instana-cassandra --template='{{index .data.password | base64decode}}'`"
EOF

if [[ "${INSTANA_PLATFORM}" == "s390x" ]]; then
cat >> core-config-base.yaml <<-EOF
  clickhouseConfigs:
    - adminUser: '${CLICKHOUSE_USER}'
      adminPassword: '${CLICKHOUSE_USER_PASS}'
      user: '${CLICKHOUSE_USER}'
      password: '${CLICKHOUSE_USER_PASS}'
EOF
else
cat >> core-config-base.yaml <<-EOF
  clickhouseConfigs:
    - adminUser: "clickhouseuser"
      adminPassword: "`${KUBECTL} get secret chi-passwords -n instana-clickhouse --template='{{index .data.clickhouseuser_password | base64decode}}'`"
      user: "clickhouseuser"
      password: "`${KUBECTL} get secret chi-passwords -n instana-clickhouse --template='{{index .data.clickhouseuser_password | base64decode}}'`"
EOF
fi

    # Merge with custom core_config.yaml
    yq eval-all '. as $item ireduce ({}; . *+ $item)' core-config-base.yaml core_config.yaml > core-config.yaml


    # Preparing instana-units config
    echo "Generating instana-units secret..."
    
cat > unit-config-base.yaml <<-EOF
licenses: `cat ${INSTANA_AIRGAPPED_FOLDER}/license.json`
EOF
    # Merge with custom unit_config.yaml
    yq eval-all '. as $item ireduce ({}; . *+ $item)' unit-config-base.yaml unit_config.yaml > unit-config.yaml


    echo "Creating instana-core, instana-units secrets..."
    if ${KUBECTL} get secret instana-core -n instana-core &> /dev/null; then
        ${KUBECTL} delete secret beeinstana-kafka-creds -n beeinstana
    fi
    ${KUBECTL} create secret generic instana-core --namespace instana-core --from-file=config.yaml=core-config.yaml

    if ${KUBECTL} get secret ${INSTANA_TENANT_NAME}-${INSTANA_UNIT_NAME} -n instana-units &> /dev/null; then
        ${KUBECTL} delete secret ${INSTANA_TENANT_NAME}-${INSTANA_UNIT_NAME} -n instana-units
    fi
    ${KUBECTL} create secret generic ${INSTANA_TENANT_NAME}-${INSTANA_UNIT_NAME} --namespace instana-units --from-file=config.yaml=unit-config.yaml

    rm -f core-config-base.yaml unit-config-base.yaml

    echo "Creating instana-core..."
    ${KUBECTL} apply -f ${MANIFEST_FILENAME_CORE}

    # echo "Waiting for Core datastore migration..."
    # sleep 30
    # ${KUBECTL} wait -n instana-core --for=jsonpath='{.status.dbMigrationStatus}'=Ready core instana-core --timeout=3000s

    echo "Waiting for Core to become ready..."
    # sleep 10
    # ${KUBECTL} wait -n instana-core --for=jsonpath='{.status.componentsStatus}'=Ready core instana-core --timeout=3000s
    ${KUBECTL} wait -n instana-core \
        --for=jsonpath='{.status.version}'=${INSTANA_OPERATOR_IMAGE_TAG} \
        --for=jsonpath='{.status.instanaVersion}'=${INSTANA_CORE_IMAGE_TAG} \
        --for=jsonpath='{.status.dbMigrationStatus}'=Ready \
        --for=jsonpath='{.status.componentsStatus}'=Ready \
        core instana-core --timeout=3000s


    echo "Creating instana-unit..."
    ${KUBECTL} apply -f ${MANIFEST_FILENAME_UNIT}
    # sleep 10
    # echo "Waiting for unit datasore migration..."
    # ${KUBECTL} wait -n instana-units --for=jsonpath='{.status.dbMigrationStatus}'=Ready unit `${KUBECTL} -n instana-units get units -o jsonpath='{.items[0].metadata.name}'` --timeout=3000s

    echo "Waiting for unit to become ready..."
    # ${KUBECTL} wait -n instana-units --for=jsonpath='{.status.componentsStatus}'=Ready unit `${KUBECTL} -n instana-units get units -o jsonpath='{.items[0].metadata.name}'` --timeout=3000s
    ${KUBECTL} wait -n instana-units \
        --for=jsonpath='{.status.version}'=${INSTANA_OPERATOR_IMAGE_TAG} \
        --for=jsonpath='{.status.instanaVersion}'=${INSTANA_CORE_IMAGE_TAG} \
        --for=jsonpath='{.status.dbMigrationStatus}'=Ready \
        --for=jsonpath='{.status.componentsStatus}'=Ready \
        unit ${INSTANA_TENANT_NAME}-${INSTANA_UNIT_NAME} --timeout=3000s

    echo "Creating routes..."
    ${KUBECTL} create route passthrough ui-client-tenant --hostname=${INSTANA_TENANT_DOMAIN} --service=gateway-v2 --port=https -n instana-core
    ${KUBECTL} create route passthrough ui-client-ssl --hostname=${INSTANA_BASE_DOMAIN} --service=gateway-v2 --port=https -n instana-core
    ${KUBECTL} create route passthrough acceptor  --hostname=${INSTANA_AGENT_ACCEPTOR}  --service=acceptor  --port=8600  -n instana-core
    ${KUBECTL} create route passthrough otlp-http-acceptor --hostname=${INSTANA_OTLP_HTTP_ACCEPTOR} --service=gateway-v2  --port=https -n instana-core
    ${KUBECTL} create route passthrough otlp-grpc-acceptor --hostname=${INSTANA_OTLP_GRPC_ACCEPTOR} --service=gateway-v2  --port=https -n instana-core
}

#### Installing Instana operator and apply for backend ########

case "$1" in
  delete|delete_crd)
      backend_delete_crd $@
      ;;
  uninstall_operator)
      backend_uninstall_operator $@
      ;;
  uninstall)
      backend_uninstall $@
      ;;
  *|install)
      backend_install $@
      ;;
esac

