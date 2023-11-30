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

