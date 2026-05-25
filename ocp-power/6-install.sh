#!/bin/bash

echo "Reading credentials.env..."
source ../credentials.env
source ../artifacts-${INSTANA_PLATFORM}.env

#### DATASTORES ######

echo "Upgrading or installing Kafka..."
${KUBECTL} create namespace instana-kafka
${KUBECTL} create secret docker-registry instana-registry \
  --namespace=instana-kafka \
  --docker-username=${INSTANA_IMAGE_REGISTRY_USERNAME} \
  --docker-password=${INSTANA_IMAGE_REGISTRY_PASSWORD} \
  --docker-server=${INSTANA_IMAGE_REGISTRY}

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



echo "Upgrading or installing Postgres..."
${KUBECTL} create namespace instana-postgres
${KUBECTL} create secret docker-registry instana-registry --namespace=instana-postgres \
  --docker-server=${INSTANA_IMAGE_REGISTRY} \
  --docker-username=${INSTANA_IMAGE_REGISTRY_USERNAME} \
  --docker-password=${INSTANA_IMAGE_REGISTRY_PASSWORD}

# ${KUBECTL} -n instana-postgres apply -f ${MANIFEST_FILENAME_POSTGRES_SCC}


if ${KUBECTL} get secret instanaadmin -n instana-postgres >/dev/null 2>&1; then
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
${KUBECTL} apply -f postgres-secret.yaml
else
  echo "instanaadmin secret already exists in instana-postgres namespace." 
fi

helm upgrade --install cnpg -n instana-postgres --wait \
  --set image.repository=${POSTGRES_OPERATOR_IMAGE_NAME} \
  --set image.tag=${POSTGRES_OPERATOR_IMAGE_TAG} \
  --set imagePullSecrets[0].name=instana-registry \
  --set containerSecurityContext.runAsUser=`${KUBECTL} get namespace instana-postgres -o jsonpath='{.metadata.annotations.openshift\.io\/sa\.scc\.uid-range}' | cut -d/ -f 1` \
  --set containerSecurityContext.runAsGroup=`${KUBECTL} get namespace instana-postgres -o jsonpath='{.metadata.annotations.openshift\.io\/sa\.scc\.uid-range}' | cut -d/ -f 1` \
  ${INSTANA_AIRGAPPED_FOLDER}/${POSTGRES_HELM_CHART}

${KUBECTL} -n instana-postgres apply -f ${MANIFEST_FILENAME_POSTGRES}






echo "Upgrading or installing Cassandra..."
${KUBECTL} -n instana-cassandra apply -f ${MANIFEST_FILENAME_CASSANDRA_SCC}

${KUBECTL} create namespace instana-cassandra
${KUBECTL} create serviceaccount cassandra -n instana-cassandra

${KUBECTL} create secret docker-registry instana-registry --namespace=instana-cassandra \
  --docker-server=${INSTANA_IMAGE_REGISTRY} \
  --docker-username=${INSTANA_IMAGE_REGISTRY_USERNAME} \
  --docker-password=${INSTANA_IMAGE_REGISTRY_PASSWORD}

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
  --set appVersion=${CASSANDRA_OPERATOR_APP_VERSION} \
  --set imageConfig.systemLogger=${CASSANDRA_SYSTEMLOGGER_IMAGE_NAME}  \
  --set imageConfig.k8ssandraClient=${CASSANDRA_K8SSANDRACLIENT_IMAGE_NAME} \
  ${INSTANA_AIRGAPPED_FOLDER}/${CASSANDRA_HELM_CHART}

${KUBECTL} -n instana-cassandra apply -f ${MANIFEST_FILENAME_CASSANDRA} 



echo "Upgrading or installing Clickhouse..."
${KUBECTL} -n instana-clickhouse apply -f ${MANIFEST_FILENAME_CLICKHOUSE_SCC}

${KUBECTL} create namespace instana-clickhouse
${KUBECTL} create serviceaccount clickhousekeeper -n instana-clickhouse
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


if ${KUBECTL} get secret chi-passwords -n instana-clickhouse >/dev/null 2>&1; then
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

${KUBECTL} -n instana-clickhouse apply -f ${MANIFEST_FILENAME_CLICKHOUSE_KEEPER}

echo "Waiting for Clickhouse keeper pods to be running..."
${KUBECTL} wait -n instana-clickhouse --for=jsonpath='{status.status}'=Completed chk clickhouse-keeper --timeout=3000s
${KUBECTL} -n instana-clickhouse wait --for=condition=Ready=true pod -lapp=clickhouse-keeper --timeout=3000s
sleep 30
${KUBECTL} -n instana-clickhouse apply -f ${MANIFEST_FILENAME_CLICKHOUSE}



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

if ${KUBECTL} get secret beeinstana-kafka-creds -n beeinstana >/dev/null 2>&1; then
    ${KUBECTL} delete secret beeinstana-kafka-creds -n beeinstana
fi
${KUBECTL} create secret generic beeinstana-kafka-creds -n beeinstana \
  --from-literal=username=strimzi-kafka-user \
  --from-literal=password=`${KUBECTL} get secret strimzi-kafka-user  -n instana-kafka --template='{{index .data.password | base64decode}}'`

if ${KUBECTL} get secret beeinstana-admin-creds -n beeinstana >/dev/null 2>&1; then
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


echo "Waiting for Elasticsearch to be ready..."
${KUBECTL} -n instana-elastic wait --for=jsonpath='{.status.phase}'=Ready es instana --timeout=3000s
echo "Waiting for Elasticsearch pods to be running..."
${KUBECTL} -n instana-elastic wait --for=condition=Ready=true pod -lelasticsearch.k8s.elastic.co/cluster-name=instana --timeout=3000s
echo "Waiting for Postgres cluster to be ready..."
${KUBECTL} -n instana-postgres wait --for=condition=Ready=true cluster postgres --timeout=3000s
echo "Waiting for Cassandra pods to be running..."
${KUBECTL} -n instana-cassandra wait --for=condition=Ready=true pod -lapp.kubernetes.io/name=cassandra --timeout=3000s
echo "Waiting for Clickhouse pods to be running..."
${KUBECTL} -n instana-clickhouse wait --for=jsonpath='{.status.status}'=Completed chi instana --timeout=3000s
${KUBECTL} -n instana-clickhouse wait --for=condition=Ready=true pod -lclickhouse.altinity.com/chi=instana --timeout=3000s
echo "Waiting for Beeinstana pods to be running..."
${KUBECTL} -n beeinstana wait --for=condition=Ready=true pod -lapp.kubernetes.io/name=beeinstana --timeout=3000s


######################


#### OPERATOR ########

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



# Creating/Updating instana tls secret
if ! ${KUBECTL} get secret instana-tls -n instana-core >/dev/null 2>&1; then
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
  clickhouseConfigs:
    # - adminUser: "${CLICKHOUSE_USER}"
    #   adminPassword: "${CLICKHOUSE_USER_PASS}"
    #   user: "${CLICKHOUSE_USER}"
    #   password: "${CLICKHOUSE_USER_PASS}"
    - adminUser: "clickhouseuser"
      adminPassword: "`${KUBECTL} get secret chi-passwords -n instana-clickhouse --template='{{index .data.clickhouseuser_password | base64decode}}'`"
      user: "clickhouseuser"
      password: "`${KUBECTL} get secret chi-passwords -n instana-clickhouse --template='{{index .data.clickhouseuser_password | base64decode}}'`"
EOF
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
if ${KUBECTL} get secret instana-core -n instana-core >/dev/null 2>&1; then
    ${KUBECTL} delete secret beeinstana-kafka-creds -n beeinstana
fi
${KUBECTL} create secret generic instana-core --namespace instana-core --from-file=config.yaml=core-config.yaml

if ${KUBECTL} get secret ${INSTANA_TENANT_NAME}-${INSTANA_UNIT_NAME} -n instana-units >/dev/null 2>&1; then
    ${KUBECTL} delete secret ${INSTANA_TENANT_NAME}-${INSTANA_UNIT_NAME} -n instana-units
fi
${KUBECTL} create secret generic ${INSTANA_TENANT_NAME}-${INSTANA_UNIT_NAME} --namespace instana-units --from-file=config.yaml=unit-config.yaml

rm -f core-config-base.yaml unit-config-base.yaml

echo "Creating instana-core..."
${KUBECTL} apply -f ${MANIFEST_FILENAME_CORE}

echo "Waiting for Core datastore migration..."
sleep 30
${KUBECTL} wait -n instana-core --for=jsonpath='{.status.dbMigrationStatus}'=Ready core instana-core --timeout=3000s
echo "Waiting for Core components to start..."
sleep 10
${KUBECTL} wait -n instana-core --for=jsonpath='{.status.componentsStatus}'=Progressing core instana-core --timeout=3000s
sleep 10

echo "Waiting for Core to become ready..."
${KUBECTL} wait -n instana-core --for=jsonpath='{.status.componentsStatus}'=Ready core instana-core --timeout=3000s

echo "Creating instana-unit..."
${KUBECTL} apply -f ${MANIFEST_FILENAME_UNIT}
sleep 10
echo "Waiting for unit datasore migration..."
${KUBECTL} wait -n instana-units --for=jsonpath='{.status.dbMigrationStatus}'=Ready unit `${KUBECTL} -n instana-units get units -o jsonpath='{.items[0].metadata.name}'` --timeout=3000s
echo "Waiting for unit to become ready..."
${KUBECTL} wait -n instana-units --for=jsonpath='{.status.componentsStatus}'=Ready unit `${KUBECTL} -n instana-units get units -o jsonpath='{.items[0].metadata.name}'` --timeout=3000s


######################


echo "Creating routes..."
${KUBECTL} create route passthrough ui-client-tenant --hostname=${INSTANA_TENANT_DOMAIN} --service=gateway-v2 --port=https -n instana-core
${KUBECTL} create route passthrough ui-client-ssl --hostname=${INSTANA_BASE_DOMAIN} --service=gateway-v2 --port=https -n instana-core
${KUBECTL} create route passthrough acceptor  --hostname=${INSTANA_AGENT_ACCEPTOR}  --service=acceptor  --port=8600  -n instana-core
${KUBECTL} create route passthrough otlp-http-acceptor --hostname=${INSTANA_OTLP_HTTP_ACCEPTOR} --service=gateway-v2  --port=https -n instana-core
${KUBECTL} create route passthrough otlp-grpc-acceptor --hostname=${INSTANA_OTLP_GRPC_ACCEPTOR} --service=gateway-v2  --port=https -n instana-core
echo "Done."