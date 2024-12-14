#!/bin/bash

echo "Reading credentials.env..."
source ../credentials.env
source ../artefacts.env

#### DATASTORES ######

echo "Installing zookeeper..."
${KUBECTL} create namespace instana-zookeeper

${KUBECTL} create secret docker-registry instana-registry \
  --namespace=instana-zookeeper \
  --docker-username=${INSTANA_IMAGE_REGISTRY_USERNAME} \
  --docker-password=${INSTANA_IMAGE_REGISTRY_PASSWORD} \
  --docker-server=${INSTANA_IMAGE_REGISTRY}

helm install instana ${ZOOKEEPER_HELM_CHART} -n instana-zookeeper \
  --create-namespace --wait \
  --set image.registry=${INSTANA_IMAGE_REGISTRY} \
  --set image.repository=${ZOOKEEPER_OPERATOR_IMAGE_NAME} \
  --set image.tag=${ZOOKEEPER_OPERATOR_IMAGE_TAG} \
  --set global.imagePullSecrets={"instana-registry"}

${KUBECTL} -n instana-zookeeper wait --for=condition=Ready=true pod --all --timeout=3000s

${KUBECTL} create namespace instana-clickhouse
${KUBECTL} create secret docker-registry instana-registry \
  --namespace=instana-clickhouse \
  --docker-username=${INSTANA_IMAGE_REGISTRY_USERNAME} \
  --docker-password=${INSTANA_IMAGE_REGISTRY_PASSWORD} \
  --docker-server=${INSTANA_IMAGE_REGISTRY}
${KUBECTL} apply -f ${MANIFEST_FILENAME_ZOOKEEPER} -n instana-clickhouse






echo "Installing kafka..."
${KUBECTL} create namespace instana-kafka
${KUBECTL} create secret docker-registry instana-registry \
  --namespace=instana-kafka \
  --docker-username=${INSTANA_IMAGE_REGISTRY_USERNAME} \
  --docker-password=${INSTANA_IMAGE_REGISTRY_PASSWORD} \
  --docker-server=${INSTANA_IMAGE_REGISTRY}

helm install strimzi ${KAFKA_HELM_CHART} -n instana-kafka --wait \
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
  --set kafka.image.tag=${KAFKA_IMAGE_TAG}

${KUBECTL} apply -f ${MANIFEST_FILENAME_KAFKA} -n instana-kafka




echo "Installing Elasticsearch..."
${KUBECTL} create namespace instana-elastic
${KUBECTL} create secret docker-registry instana-registry \
  --namespace=instana-elastic \
  --docker-username=${INSTANA_IMAGE_REGISTRY_USERNAME} \
  --docker-password=${INSTANA_IMAGE_REGISTRY_PASSWORD} \
  --docker-server=${INSTANA_IMAGE_REGISTRY}

helm install elastic-operator ${ELASTIC_HELM_CHART} -n instana-elastic --wait \
  --version=${ELASTIC_HELM_CHART_VERSION} \
  --set image.repository=${ELASTIC_OPERATOR_IMAGE_NAME} \
  --set image.tag=${ELASTIC_OPERATOR_IMAGE_TAG} \
  --set imagePullSecrets[0].name="instana-registry"

${KUBECTL} apply -f ${MANIFEST_FILENAME_ELASTICSEARCH} -n instana-elastic



echo "Installing Postgres..."
${KUBECTL} create namespace instana-postgres
${KUBECTL} create secret docker-registry instana-registry --namespace=instana-postgres \
  --docker-server=${INSTANA_IMAGE_REGISTRY} \
  --docker-username=${INSTANA_IMAGE_REGISTRY_USERNAME} \
  --docker-password=${INSTANA_IMAGE_REGISTRY_PASSWORD}

# ${KUBECTL} -n instana-postgres apply -f ${MANIFEST_FILENAME_POSTGRES_SCC}

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

helm install cnpg ${POSTGRES_HELM_CHART} --wait \
  --set image.repository=${POSTGRES_OPERATOR_IMAGE_NAME} \
  --set image.tag=${POSTGRES_OPERATOR_IMAGE_TAG} \
  --set imagePullSecrets[0].name=instana-registry \
  --set containerSecurityContext.runAsUser=`${KUBECTL} get namespace instana-postgres -o jsonpath='{.metadata.annotations.openshift\.io\/sa\.scc\.uid-range}' | cut -d/ -f 1` \
  --set containerSecurityContext.runAsGroup=`${KUBECTL} get namespace instana-postgres -o jsonpath='{.metadata.annotations.openshift\.io\/sa\.scc\.uid-range}' | cut -d/ -f 1` \
  -n instana-postgres 

${KUBECTL} -n instana-postgres apply -f ${MANIFEST_FILENAME_POSTGRES}






echo "Installing Cassandra..."
${KUBECTL} -n instana-cassandra apply -f ${MANIFEST_FILENAME_CASSANDRA_SCC}

${KUBECTL} create namespace instana-cassandra
${KUBECTL} create secret docker-registry instana-registry --namespace=instana-cassandra \
  --docker-server=${INSTANA_IMAGE_REGISTRY} \
  --docker-username=${INSTANA_IMAGE_REGISTRY_USERNAME} \
  --docker-password=${INSTANA_IMAGE_REGISTRY_PASSWORD}

helm install cass-operator ${CASSANDRA_HELM_CHART} -n instana-cassandra --wait \
  --set securityContext.runAsGroup=999 \
  --set securityContext.runAsUser=999 \
  --set image.registry=${CASSANDRA_IMAGE_REGISTRY} \
  --set image.repository=${CASSANDRA_OPERATOR_IMAGE_NAME} \
  --set image.tag=${CASSANDRA_OPERATOR_IMAGE_TAG} \
  --set imagePullSecrets[0].name=instana-registry \
  --set appVersion=${CASSANDRA_OPERATOR_APP_VERSION} \
  --set appVersion=${CASSANDRA_OPERATOR_APP_VERSION} \
  --set imageConfig.systemLogger=${CASSANDRA_SYSTEMLOGGER_IMAGE_NAME}  \
  --set imageConfig.k8ssandraClient=${CASSANDRA_K8SSANDRACLIENT_IMAGE_NAME}

${KUBECTL} -n instana-cassandra apply -f ${MANIFEST_FILENAME_CASSANDRA} 



echo "Waiting for Zookeeper pods to be running..."
${KUBECTL} wait -n instana-clickhouse --for=jsonpath='{.status.conditions[0].status}'=True zk instana-zookeeper --timeout=3000s
${KUBECTL} -n instana-clickhouse wait --for=condition=Ready=true pod -lrelease=instana-zookeeper --timeout=3000s


echo "Installing Clickhouse..."
${KUBECTL} -n instana-clickhouse apply -f ${MANIFEST_FILENAME_CLICKHOUSE_SCC}

# ${KUBECTL} create namespace instana-clickhouse
${KUBECTL} create secret docker-registry clickhouse-image-secret \
  --namespace=instana-clickhouse \
  --docker-username=${INSTANA_IMAGE_REGISTRY_USERNAME} \
  --docker-password=${INSTANA_IMAGE_REGISTRY_PASSWORD} \
  --docker-server=${INSTANA_IMAGE_REGISTRY}

helm install clickhouse-operator ${CLICKHOUSE_HELM_CHART} \
  -n instana-clickhouse --wait \
  --set operator.image.repository=${CLICKHOUSE_OPERATOR_IMAGE_NAME} \
  --set operator.image.tag=${CLICKHOUSE_OPERATOR_IMAGE_TAG} \
  --set imagePullSecrets[0].name="instana-registry"

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

${KUBECTL} -n instana-clickhouse apply -f ${MANIFEST_FILENAME_CLICKHOUSE}



echo "Waiting for Kafka pods to be running..."
# ${KUBECTL} -n instana-kafka wait --for=condition=Ready=true -f ${MANIFEST_FILENAME_KAFKA} --timeout=3000s
${KUBECTL} -n instana-kafka wait --for=condition=Ready=true pod -lstrimzi.io/component-type=zookeeper --timeout=3000s
${KUBECTL} -n instana-kafka wait --for=condition=Ready=true pod -lstrimzi.io/component-type=kafka --timeout=3000s


echo "Installing Beeinstana..."
${KUBECTL} create namespace beeinstana
${KUBECTL} create secret docker-registry instana-registry --namespace=beeinstana \
  --docker-server=${INSTANA_IMAGE_REGISTRY} \
  --docker-username=${INSTANA_IMAGE_REGISTRY_USERNAME} \
  --docker-password=${INSTANA_IMAGE_REGISTRY_PASSWORD}
# for k8s and OCP 4.10:
#helm install beeinstana instana/beeinstana-operator --namespace=beeinstana
# For a cluster on Red Hat OpenShift 4.11 and later:
helm install beeinstana ${BEEINSTANA_HELM_CHART} --namespace=beeinstana --wait \
  --set operator.securityContext.seccompProfile.type=RuntimeDefault \
  --set image.registry=${INSTANA_IMAGE_REGISTRY} \
  --set image.repository=${BEEINSTANA_OPERATOR_IMAGE_NAME} \
  --set image.tag=${BEEINSTANA_OPERATOR_IMAGE_TAG}

while ! ${KUBECTL} get secret strimzi-kafka-user -n instana-kafka; do echo "Waiting for strimzi-kafka-user secret in instana-kafka. CTRL-C to exit."; sleep 10; done

${KUBECTL} create secret generic beeinstana-kafka-creds -n beeinstana \
  --from-literal=username=strimzi-kafka-user \
  --from-literal=password=`${KUBECTL} get secret strimzi-kafka-user  -n instana-kafka --template='{{index .data.password | base64decode}}'`
${KUBECTL} create secret generic beeinstana-admin-creds -n beeinstana \
  --from-literal=username=beeinstana-user \
  --from-literal=password=`openssl rand -base64 24 | tr -cd 'a-zA-Z0-9' | head -c32; echo`

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
image:
  registry: ${INSTANA_IMAGE_REGISTRY}
  repository: ${INSTANA_OPERATOR_IMAGE_NAME}
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



# Generate certificate files
if [[ ${TLS_CERTIFICATE_GENERATE} == "YES" ]]; then
    echo "Generating SSL certificates ${TLS_CERTIFICATE_FILE}/${TLS_KEY_FILE} ..."
    openssl genrsa -out ca.key 2048
    openssl req -new -x509 -days 365 -key ca.key \
        -subj "/C=${TLS_CERTIFICATE_GENERATE_C}/ST=${TLS_CERTIFICATE_GENERATE_ST}/L=${TLS_CERTIFICATE_GENERATE_L}/O=${TLS_CERTIFICATE_GENERATE_O}/CN=${TLS_CERTIFICATE_GENERATE_CN}" -out ca.crt
    openssl req -newkey rsa:2048 -nodes -keyout ${TLS_KEY_FILE} \
        -subj "/C=${TLS_CERTIFICATE_GENERATE_C}/ST=${TLS_CERTIFICATE_GENERATE_ST}/L=S${TLS_CERTIFICATE_GENERATE_L}/O=${TLS_CERTIFICATE_GENERATE_O}/CN=*.${INSTANA_BASE_DOMAIN}" -out tls.csr
    openssl x509 -req -extfile <(printf "subjectAltName=DNS:${INSTANA_BASE_DOMAIN},DNS:${INSTANA_TENANT_DOMAIN},DNS:${INSTANA_AGENT_ACCEPTOR},DNS:${INSTANA_OTLP_GRPC_ACCEPTOR},DNS:${INSTANA_OTLP_HTTP_ACCEPTOR}") \
        -days 365 -in tls.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out ${TLS_CERTIFICATE_FILE}
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


cat > core-config.yaml <<-EOF
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
storageConfigs:
#  rawSpans:
#    # Required if using S3 or compatible storage bucket.
#    # Credentials should be configured.
#    # Not required if IRSA on EKS is used.
#    s3Config:
#      accessKeyId: ...
#      secretAccessKey: ...
#    # Required if using Google Cloud Storage.
#    # Credentials should be configured.
#    # Not required if GKE with workload identity is used.
#    gcloudConfig:
#      serviceAccountKey: ...

# SAML/OIDC configuration
# serviceProviderConfig:
#   # Password for the key/cert file
#   keyPassword: ${KEY_PEM_PASSWORD}
#   # The combined key/cert file
#   pem: |
#`#sed  's/^/    /' sp.pem`
# # Required if a proxy is configured that needs authentication
# proxyConfig:
#   # Proxy user
#   user: myproxyuser
#   # Proxy password
#   password: my proxypassword
# emailConfig:
#   # Required if SMTP is used for sending e-mails and authentication is required
#   smtpConfig:
#     user: mysmtpuser
#     password: mysmtppassword
#   # Required if using for sending e-mail.
#   # Credentials should be configured.
#   # Not required if using IRSA on EKS.
#   sesConfig:
#     accessKeyId: ...
#     secretAccessKey: ...
# # Optional custom CA certificate to be added to component trust stores
# # in case internal systems Instana talks to (e.g. LDAP or alert receivers) use a custom CA.
# customCACert: |
#   -----BEGIN CERTIFICATE-----
#   <snip/>
#   -----END CERTIFICATE-----
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


# Preparing instana-units config
echo "Generating instana-units secret..."
cat > unit-config.yaml <<-EOF
# The initial user of this tenant unit with admin role, default admin@instana.local.
# Must be a valid e-maiol address.
# NOTE:
# This only applies when setting up the tenant unit.
# Changes to this value won't have any effect.
initialAdminUser: ${INSTANA_ADMIN_USER}
# The initial admin password.
# NOTE:
# This is only used for the initial tenant unit setup.
# Changes to this value won't have any effect.
initialAdminPassword: ${INSTANA_ADMIN_PASSWORD}
# The Instana license. Can be a plain text string or a JSON array encoded as string. Deprecated. Use 'licenses' instead. Will no longer be supported in release 243.
# license: mylicensestring # This would also work: '["mylicensestring"]'
# A list of Instana licenses. Multiple licenses may be specified.
# licenses: [ "license1", "license2" ]
licenses: `cat license.json`
# A list of agent keys. Specifying multiple agent keys enables gradually rotating agent keys.
agentKeys:
  - ${DOWNLOAD_KEY}
downloadKey: ${DOWNLOAD_KEY}
EOF

# Creating secrets
echo "Creating instana-core, instana-units and instana-tls secrets..."
${KUBECTL} create secret tls instana-tls --namespace instana-core \
    --cert=${TLS_CERTIFICATE_FILE} \
    --key=${TLS_KEY_FILE}

${KUBECTL} create secret generic instana-core --namespace instana-core --from-file=config.yaml=core-config.yaml

${KUBECTL} create secret generic ${INSTANA_TENANT_NAME}-${INSTANA_UNIT_NAME} --namespace instana-units --from-file=config.yaml=unit-config.yaml


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
${KUBECTL} create route passthrough ui-client-tenant --hostname=${INSTANA_TENANT_DOMAIN} --service=gateway --port=https -n instana-core
${KUBECTL} create route passthrough ui-client-ssl --hostname=${INSTANA_BASE_DOMAIN} --service=gateway --port=https -n instana-core
${KUBECTL} create route passthrough acceptor  --hostname=${INSTANA_AGENT_ACCEPTOR}  --service=acceptor  --port=8600  -n instana-core

echo "Done."