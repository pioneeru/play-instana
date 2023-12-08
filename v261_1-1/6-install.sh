#!/bin/bash

echo "Reading credentials.env..."
source ../credentials.env

#### DATASTORES ######

echo "Installing zookeeper..."
${KUBECTL} create namespace instana-zookeeper

${KUBECTL} create secret docker-registry docker-image-secret \
  --namespace=instana-zookeeper \
  --docker-username=${DOCKER_USERNAME} \
  --docker-password=${DOCKER_PASSWORD} \
  --docker-server=docker.io

helm install instana zookeeper-operator-0.2.15.tgz -n instana-zookeeper \
  --set "global.imagePullSecrets={docker-image-secret}" \
  --create-namespace

  # --set "securityContext.allowPrivilegeEscalation=false" \
  # --set "securityContext.runAsNonRoot=true" \
  # --set "securityContext.seccompProfile.type=RuntimeDefault" \
  # --set "securityContext.capabilities.drop[0]=ALL" \
  # --set "hooks.securityContext.seccompProfile.type=RuntimeDefault" \
  # --set "hooks.securityContext.runAsNonRoot=true" \
  # --set "hooks.securityContext.allowPrivilegeEscalation=false" \
  # --set "hooks.securityContext.capabilities.drop[0]=ALL" \

${KUBECTL} -n instana-zookeeper wait --for=condition=Ready=true pod --all --timeout=3000s
# ${KUBECTL} wait -n instana-core --for=jsonpath='{.status.componentsStatus}'=Ready core instana-core --timeout=3000s

${KUBECTL} create namespace instana-clickhouse
${KUBECTL} apply -f ${MANIFEST_FILENAME_ZOOKEEPER} -n instana-clickhouse


echo "Installing kafka..."
helm install strimzi strimzi-kafka-operator-helm-3-chart-0.36.0.tgz -n instana-kafka \
  --set "securityContext.seccompProfile.type=RuntimeDefault" \
  --create-namespace
${KUBECTL} apply -f ${MANIFEST_FILENAME_KAFKA} -n instana-kafka


echo "Installing Elasticsearch..."
helm install elastic-operator eck-operator-2.8.0.tgz -n instana-elastic \
  --set "securityContext.seccompProfile.type=RuntimeDefault" \
  --create-namespace
${KUBECTL} apply -f ${MANIFEST_FILENAME_ELASTICSEARCH} -n instana-elastic


echo "Installing Postgres..."
helm install postgres-operator postgres-operator-1.10.0.tgz -n instana-postgres \
  --set configGeneral.kubernetes_use_configmaps=true \
  --set securityContext.runAsUser=101 \
  --create-namespace 
${KUBECTL} -n instana-postgres apply -f ${MANIFEST_FILENAME_POSTGRES_SCC}
${KUBECTL} -n instana-postgres apply -f ${MANIFEST_FILENAME_POSTGRES}


echo "Installing Cassandra..."
helm install cass-operator cass-operator-0.42.0.tgz -n instana-cassandra \
  --set securityContext.runAsGroup=999 \
  --set securityContext.runAsUser=999 \
  --create-namespace
${KUBECTL} -n instana-cassandra apply -f ${MANIFEST_FILENAME_CASSANDRA_SCC}
sleep 30
${KUBECTL} -n instana-cassandra apply -f ${MANIFEST_FILENAME_CASSANDRA} 



echo "Waiting for Zookeeper pods to be running..."
${KUBECTL} wait -n instana-clickhouse --for=jsonpath='{.status.conditions[0].status}'=True zk instana-zookeeper --timeout=3000s
${KUBECTL} -n instana-clickhouse wait --for=condition=Ready=true pod -lrelease=instana-zookeeper --timeout=3000s


echo "Installing Clickhouse..."
helm install clickhouse-operator altinity-clickhouse-operator-0.21.2.tgz -n instana-clickhouse \
  --create-namespace
${KUBECTL} create secret docker-registry clickhouse-image-secret \
  --namespace=instana-clickhouse \
  --docker-username=_ \
  --docker-password=${DOWNLOAD_KEY} \
  --docker-server=artifact-public.instana.io
${KUBECTL} create secret docker-registry docker-image-secret \
  --namespace=instana-clickhouse \
  --docker-username=${DOCKER_USERNAME} \
  --docker-password=${DOCKER_PASSWORD} \
  --docker-server=docker.io
# ${KUBECTL} -n instana-clickhouse apply -f ${MANIFEST_FILENAME_CLICKHOUSE_SCC}
${KUBECTL} -n instana-clickhouse apply -f ${MANIFEST_FILENAME_CLICKHOUSE}



echo "Waiting for Kafka pods to be running..."
${KUBECTL} -n instana-kafka wait --for=condition=Ready=true -f ${MANIFEST_FILENAME_KAFKA} --timeout=3000s
${KUBECTL} -n instana-kafka wait --for=condition=Ready=true pod -lstrimzi.io/component-type=zookeeper --timeout=3000s
${KUBECTL} -n instana-kafka wait --for=condition=Ready=true pod -lstrimzi.io/component-type=kafka --timeout=3000s


echo "Installing Beeinstana..."
${KUBECTL} create namespace beeinstana
${KUBECTL} create secret docker-registry instana-registry --namespace=beeinstana \
  --docker-server=artifact-public.instana.io \
  --docker-username _ \
  --docker-password=$DOWNLOAD_KEY
# for k8s and OCP 4.10:
#helm install beeinstana instana/beeinstana-operator --namespace=beeinstana
# For a cluster on Red Hat OpenShift 4.11 and later:
helm install beeinstana beeinstana-operator-v1.40.0.tgz --namespace=beeinstana \
  --set operator.securityContext.seccompProfile.type=RuntimeDefault
${KUBECTL} create secret generic beeinstana-kafka-creds -n beeinstana \
  --from-literal=username=strimzi-kafka-user \
  --from-literal=password=`${KUBECTL} get secret strimzi-kafka-user  -n instana-kafka --template='{{index .data.password | base64decode}}'`
${KUBECTL} create secret generic beeinstana-admin-creds -n beeinstana \
  --from-literal=username=beeinstana-user \
  --from-literal=password=${BEEINSTANA_ADMIN_PASS}

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
echo "Waiting for Postgres pods to be running..."
${KUBECTL} -n instana-postgres wait --for=condition=Ready=true pod -lcluster-name=postgres --timeout=3000s
echo "Waiting for Clickhouse pods to be running..."
${KUBECTL} -n instana-clickhouse wait --for=jsonpath='{.status.status}'=Completed chi instana --timeout=3000s
${KUBECTL} -n instana-clickhouse wait --for=condition=Ready=true pod -lclickhouse.altinity.com/chi=instana --timeout=3000s
echo "Waiting for Cassandra pods to be running..."
${KUBECTL} -n instana-cassandra wait --for=condition=Ready=true pod -lapp.kubernetes.io/name=cassandra --timeout=3000s
echo "Waiting for Beeinstana pods to be running..."
${KUBECTL} -n beeinstana wait --for=condition=Ready=true pod -lapp.kubernetes.io/name=beeinstana --timeout=3000s


######################


#### OPERATOR ########

echo "Installing instana-operator"
${KUBECTL} create ns instana-operator

${KUBECTL} create secret docker-registry instana-registry \
    --namespace=instana-operator \
    --docker-username=_ \
    --docker-password=$DOWNLOAD_KEY \
    --docker-server=artifact-public.instana.io

cat << EOF > instana-operator-values.yaml
#image:
#  registry: my.registry.com
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
    --docker-username=_ \
    --docker-password=$DOWNLOAD_KEY \
    --docker-server=artifact-public.instana.io

${KUBECTL} create secret docker-registry instana-registry \
    --namespace=instana-units \
    --docker-username=_ \
    --docker-password=$DOWNLOAD_KEY \
    --docker-server=artifact-public.instana.io



# Generate certificate files
if [[ ${TLS_CERTIFICATE_GENERATE} == "YES" ]]; then
    echo "Generating SSL certificates tls.csr/tls.key ..."
    openssl genrsa -out ca.key 2048
    openssl req -new -x509 -days 365 -key ca.key \
        -subj "/C=CN/ST=GD/L=SZ/O=IBM/CN=IBM Root CA" -out ca.crt
    openssl req -newkey rsa:2048 -nodes -keyout tls.key \
        -subj "/C=CN/ST=GD/L=SZ/O=IBM./CN=*.${INSTANA_BASE_DOMAIN}" -out tls.csr
    openssl x509 -req -extfile <(printf "subjectAltName=DNS:${INSTANA_BASE_DOMAIN},DNS:${INSTANA_TENANT_DOMAIN},DNS:${INSTANA_AGENT_ACCEPTOR}") \
        -days 365 -in tls.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out tls.crt
fi

# Preparing instana-core config
echo "Generating instana-core config..."
# openssl dhparam -out dhparams.pem 2048
# openssl genrsa -aes128 -out key.pem -passout pass:${KEY_PEM_PASSWORD} 2048
openssl genrsa -out key.pem -passout pass:${KEY_PEM_PASSWORD} 4096   ### FIPS

cat > internal_csr_details.txt <<-EOF
[req]
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = dn

[dn]
C=US
ST=TX
L=Austin
O=IBM
OU=Instana
emailAddress=my@email.ibm.com
CN=${INSTANA_BASE_DOMAIN}
EOF

openssl req -new -x509 -key key.pem -days 365 \
	-passin pass:${KEY_PEM_PASSWORD} -out cert.pem \
	-config internal_csr_details.txt

cat key.pem cert.pem > sp.pem


cat > core-config.yaml <<-EOF
# Diffie-Hellman parameters to use
dhParams: |
`sed  's/^/  /' dhparams.pem`
# The download key you received from us
repositoryPassword: ${DOWNLOAD_KEY}
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
serviceProviderConfig:
  # Password for the key/cert file
  keyPassword: ${KEY_PEM_PASSWORD}
  # The combined key/cert file
  pem: |
`sed  's/^/    /' sp.pem`
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
    password: "${BEEINSTANA_ADMIN_PASS}"
  clickhouseConfigs:
    - adminUser: "${CLICKHOUSE_USER}"
      adminPassword: "${CLICKHOUSE_USER_PASS}"
      user: "${CLICKHOUSE_USER}"
      password: "${CLICKHOUSE_USER_PASS}"
  cassandraConfigs:
    - adminUser: instana-superuser
      adminPassword: "`${KUBECTL} get secret instana-superuser -n instana-cassandra --template='{{index .data.password | base64decode}}'`"
      user: instana-superuser
      password: "`${KUBECTL} get secret instana-superuser -n instana-cassandra --template='{{index .data.password | base64decode}}'`"
  postgresConfigs:
    - adminUser: postgres
      adminPassword: "`${KUBECTL} get secret postgres.postgres.credentials.postgresql.acid.zalan.do -n instana-postgres --template='{{index .data.password | base64decode}}'`"
      user: postgres
      password: "`${KUBECTL} get secret postgres.postgres.credentials.postgresql.acid.zalan.do -n instana-postgres --template='{{index .data.password | base64decode}}'`"
  elasticsearchConfig:
    adminUser: elastic
    adminPassword: "`${KUBECTL} get secret instana-es-elastic-user -n instana-elastic -o go-template='{{.data.elastic | base64decode}}'`"
    user: elastic
    password: "`${KUBECTL} get secret instana-es-elastic-user -n instana-elastic -o go-template='{{.data.elastic | base64decode}}'`"
  kafkaConfig:
    adminUser: strimzi-kafka-user
    adminPassword: "`${KUBECTL} get secret strimzi-kafka-user  -n instana-kafka --template='{{index .data.password | base64decode}}'`"
    consumerUser: strimzi-kafka-user
    consumerPassword: "`${KUBECTL} get secret strimzi-kafka-user  -n instana-kafka --template='{{index .data.password | base64decode}}'`"
    producerUser: strimzi-kafka-user
    producerPassword: "`${KUBECTL} get secret strimzi-kafka-user  -n instana-kafka --template='{{index .data.password | base64decode}}'`"
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
    --cert=tls.crt \
    --key=tls.key

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
# ${KUBECTL} -n instana-core patch deployment/groundskeeper --type=json --patch '
# [
#   { 
#     "op": "add",
#     "path": "/spec/template/spec/volumes/4",
#     "value":
#         {
#             "name": "synthetics",
#             "persistentVolumeClaim": {"claimName": "synthetics-volume-claim"}
#         }
#   },
#   { 
#     "op": "add",
#     "path": "/spec/template/spec/containers/0/volumeMounts/4",
#     "value":
#         {
#             "name": "synthetics",
#             "mountPath": "/mnt/synthetics"
#         }
#   }
# ]'

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