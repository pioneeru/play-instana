#!/bin/bash

echo "Reading credentials.env"
source ../credentials.env


cat << EOF > ${MANIFEST_FILENAME_ZOOKEEPER}
apiVersion: "zookeeper.pravega.io/v1beta1"
kind: "ZookeeperCluster"
metadata:
  name: instana-zookeeper
  namespace: instana-clickhouse
spec:
  # For all params and defaults, see https://github.com/pravega/zookeeper-operator/tree/master/charts/zookeeper#configuration
  replicas: 1
  pod:
    env:
    - name: ZK_SERVER_HEAP
      value: "1000"
    resources:
      requests:
        cpu: 1
        memory: 1500Mi
      limits:
        memory: 2Gi
  config:
    tickTime: 2000
    initLimit: 10
    syncLimit: 5
    maxClientCnxns: 0
    autoPurgeSnapRetainCount: 20
    autoPurgePurgeInterval: 1
  persistence:
    reclaimPolicy: Delete
    spec:
      resources:
        requests:
          storage: "10Gi"
      storageClassName: ${RWO_STORAGECLASS}
EOF


cat << EOF > ${MANIFEST_FILENAME_KAFKA}
apiVersion: kafka.strimzi.io/v1beta2
kind: Kafka
metadata:
  name: instana
  namespace: instana-kafka
  labels:
    strimzi.io/cluster: instana
spec:
  # Cruise Control needs more than 1 kafka node
  # cruiseControl: {}
  kafka:
    version: 3.6.0
    replicas: 1
    listeners:
    - name: scram
      port: 9092
      type: internal
      tls: false
      authentication:
        type: scram-sha-512
      configuration:
        useServiceDnsDomain: true
    authorization:
      type: simple
      superUsers:
      - strimzi-kafka-user
    storage:
      type: jbod
      volumes:
      - id: 0
        type: persistent-claim
        size: 50Gi
        deleteClaim: true
        class: ${RWO_STORAGECLASS}
    # config:
    #   default.replication.factor: 1
    #   min.insync.replicas: 1
    #   offsets.topic.replication.factor: 1
    #   transaction.state.log.min.isr: 1
    #   transaction.state.log.replication.factor: 1
    jvmOptions:
      -Xms: 1G
      -Xmx: 1G
  zookeeper:
    replicas: 1
    resources:
      limits:
        memory: 1Gi
      requests:
        cpu: "1"
        memory: 1Gi
    storage:
      type: persistent-claim
      size: 5Gi
      deleteClaim: true
      class: ${RWO_STORAGECLASS}
  entityOperator:
    template:
      pod:
        tmpDirSizeLimit: 100Mi
      topicOperatorContainer:
        env:
        - name: STRIMZI_USE_ZOOKEEPER_TOPIC_STORE
          value: "true"
    topicOperator: {}
    userOperator: {}
---
apiVersion: kafka.strimzi.io/v1beta2
kind: KafkaUser
metadata:
  name: strimzi-kafka-user
  namespace: instana-kafka
  labels:
    strimzi.io/cluster: instana
spec:
  authentication:
    type: scram-sha-512
  authorization:
    type: simple
    acls:
    - resource:
        type: topic
        name: '*'
        patternType: literal
      operations:
      - All
      host: "*"
    - resource:
        type: group
        name: '*'
        patternType: literal
      operations:
      - All
      host: "*"
EOF

cat << EOF > kafka-rebalance.yaml
apiVersion: kafka.strimzi.io/v1beta2
kind: KafkaRebalance
metadata:
  name: my-rebalance
  labels:
    strimzi.io/cluster: instana
# no goals specified, using the default goals from the Cruise Control configuration
spec: {}
EOF

cat << EOF > ${MANIFEST_FILENAME_ELASTICSEARCH}
apiVersion: elasticsearch.k8s.elastic.co/v1
kind: Elasticsearch
metadata:
  name: instana
  namespace: instana-elastic
spec:
  http:
    service:
      metadata: {}
      spec: {}
    tls:
      certificate: {}
      selfSignedCertificate:
        disabled: true
  monitoring:
    logs: {}
    metrics: {}
  version: 7.17.12
  nodeSets:
  - name: default
    count: 1
    config:
      node.master: true
      node.data: true
      node.ingest: true
      node.store.allow_mmap: false
    ### FIX for K8s with securityContext
    podTemplate:
    #  spec:
    #    securityContext:
    #      runAsUser: 1000
    #      runAsGroup: 1000
    #      fsGroup: 1000
    ### END OF FIX
      metadata:
        creationTimestamp: null
      spec:
        # nodeSelector:
        #   deploy-env: bank-prod
        containers:
        - env:
          - name: ES_JAVA_OPTS
            value: -Xms2g -Xmx2g
          - name: ingest.geoip.downloader.enabled
            value: "false"
          name: elasticsearch
          resources:
            limits:
              memory: 4Gi
            requests:
              cpu: "1"
              memory: 3Gi
    volumeClaimTemplates:
      - metadata:
          name: elasticsearch-data # Do not change this name unless you set up a volume mount for the data path.
        spec:
          accessModes:
            - ReadWriteOnce
          resources:
            requests:
              storage: 20Gi
          storageClassName: ${RWO_STORAGECLASS}
EOF


cat << EOF > ${MANIFEST_FILENAME_POSTGRES_SCC}
apiVersion: security.openshift.io/v1
kind: SecurityContextConstraints
metadata:
  name: postgres-scc
runAsUser:
  type: MustRunAs
  uid: 101
seLinuxContext:
  type: RunAsAny
fsGroup:
  type: RunAsAny
allowHostDirVolumePlugin: false
allowHostNetwork: true
allowHostPorts: true
allowPrivilegedContainer: false
allowHostIPC: true
allowHostPID: true
readOnlyRootFilesystem: false
users:
  - system:serviceaccount:instana-postgres:postgres-operator
  - system:serviceaccount:instana-postgres:postgres-pod
  - system:serviceaccount:instana-postgres:default
EOF


cat << EOF > ${MANIFEST_FILENAME_POSTGRES}
apiVersion: "acid.zalan.do/v1"
kind: postgresql
metadata:
  name: postgres
  namespace: instana-postgres
spec:
  patroni:
    pg_hba:
      - local     all          all                            trust
      - host      all          all          0.0.0.0/0         md5
      - local     replication  standby                        trust
      - hostssl   replication  standby      all               md5
      - hostnossl all          all          all               reject
      - hostssl   all          all          all               md5
  dockerImage: ghcr.io/zalando/spilo-15:3.0-p1
  teamId: instana
  numberOfInstances: 1
  spiloRunAsUser: 101
  spiloFSGroup: 103
  spiloRunAsGroup: 103
  postgresql:
    version: "15"
    parameters:  # Expert section
      shared_buffers: "32MB"
  resources:
    limits:
      memory: 1Gi
    requests:
      cpu: 500m
      memory: 500Mi
  volume:
    size: 10Gi
    storageClass: ${RWO_STORAGECLASS}    # Optional field. You can assign a non-default StorageClass available in the cluster as needed. If you don't add this field, the default StorageClass is used.
EOF


cat << EOF > ${MANIFEST_FILENAME_CASSANDRA_SCC}
apiVersion: security.openshift.io/v1
kind: SecurityContextConstraints
metadata:
  name: cassandra-scc
runAsUser:
  type: MustRunAs
  uid: 999
seLinuxContext:
  type: RunAsAny
fsGroup:
  type: RunAsAny
allowHostDirVolumePlugin: false
allowHostNetwork: true
allowHostPorts: true
allowPrivilegedContainer: false
allowHostIPC: true
allowHostPID: true
readOnlyRootFilesystem: false
users:
  - system:serviceaccount:instana-cassandra:cass-operator
  - system:serviceaccount:instana-cassandra:default
EOF


cat << EOF > ${MANIFEST_FILENAME_CASSANDRA}
apiVersion: cassandra.datastax.com/v1beta1
kind: CassandraDatacenter
metadata:
  name: cassandra
  namespace: instana-cassandra
spec:
  clusterName: instana
  serverType: cassandra
  configBuilderImage: docker.io/datastax/cass-config-builder:1.0-ubi7
  serverVersion: "4.1.2"
  managementApiAuth:
    insecure: {}
  size: 1
  allowMultipleNodesPerWorker: false
  resources:
    requests:
      cpu: 1000m
      memory: 2Gi
    limits:
      memory: 3Gi
  storageConfig:
    cassandraDataVolumeClaimSpec:
      accessModes:
        - ReadWriteOnce
      resources:
        requests:
          storage: 100Gi
      storageClassName: ${RWO_STORAGECLASS}
  config:
    jvm-server-options:
      initial_heap_size: "1G"
      max_heap_size: "2G"
      additional-jvm-opts:
        - -Dcassandra.allow_unsafe_aggressive_sstable_expiration=true
    cassandra-yaml:
      authenticator: org.apache.cassandra.auth.PasswordAuthenticator
      authorizer: org.apache.cassandra.auth.CassandraAuthorizer
      role_manager: org.apache.cassandra.auth.CassandraRoleManager
      memtable_flush_writers: 8
      auto_snapshot: false
      gc_warn_threshold_in_ms: 10000
      otc_coalescing_strategy: DISABLED
      memtable_allocation_type: offheap_objects
      num_tokens: 256
      enable_drop_compact_storage: true
EOF

cat << EOF > ${MANIFEST_FILENAME_CLICKHOUSE_SCC}
apiVersion: security.openshift.io/v1
kind: SecurityContextConstraints
metadata:
  name: clickhouse-scc
  namespace: instana-clickhouse
runAsUser:
  type: MustRunAs
  uid: 1001
seLinuxContext:
  type: RunAsAny
fsGroup:
  type: RunAsAny
allowHostDirVolumePlugin: false
allowHostNetwork: true
allowHostPorts: true
allowPrivilegedContainer: false
allowHostIPC: true
allowHostPID: true
readOnlyRootFilesystem: false
users:
  - system:serviceaccount:instana-clickhouse:clickhouse-operator
  - system:serviceaccount:instana-clickhouse:clickhouse-operator-altinity-clickhouse-operator
  - system:serviceaccount:instana-clickhouse:default
EOF

cat << EOF > ${MANIFEST_FILENAME_CLICKHOUSE}
apiVersion: "clickhouse.altinity.com/v1"
kind: "ClickHouseInstallation"
metadata:
  name: "instana"
  namespace: "instana-clickhouse"
spec:
  defaults:
    templates:
      dataVolumeClaimTemplate: instana-clickhouse-data-volume
      logVolumeClaimTemplate: instana-clickhouse-log-volume
      serviceTemplate: service-template
  configuration:
    settings:
      max_concurrent_queries: 200
      max_table_size_to_drop: 0
      max_partition_size_to_drop: 0
      remote_servers/all-sharded/secret: "${CLICKHOUSE_ADMIN_PASS}"
      remote_servers/all-replicated/secret: "${CLICKHOUSE_ADMIN_PASS}"
      remote_servers/local/secret: "${CLICKHOUSE_ADMIN_PASS}"
    files:
      config.d/storage.xml: |
        <clickhouse>
          <logger>
            <level>information</level>
          </logger>
          <storage_configuration>
            <disks>
              <default/>
            </disks>
            <policies>
              <logs_policy>
                <volumes>
                  <data>
                    <disk>default</disk>
                  </data>
                </volumes>
              </logs_policy>
            </policies>
          </storage_configuration>
        </clickhouse>
    clusters:
      - name: local
        templates:
          podTemplate: clickhouse
        layout:
          shardsCount: 1
          replicasCount: 2  # The the replication count of 2 is fixed for Instana backend installations
        schemaPolicy:
          replica: None
          shard: None
    zookeeper:
      nodes:
        - host: instana-zookeeper-headless.instana-clickhouse
    profiles:
      default/max_memory_usage: 1000000000
      default/joined_subquery_requires_alias: 0
      default/max_execution_time: 100
      default/max_query_size: 1048576
      default/use_uncompressed_cache: 0
      default/enable_http_compression: 1
      default/load_balancing: random
      default/background_pool_size: 32
      default/background_schedule_pool_size: 32
      default/distributed_directory_monitor_split_batch_on_failure: 1
      default/distributed_directory_monitor_batch_inserts: 1
      default/insert_distributed_sync: 1
      default/log_queries: 1
      default/log_query_views: 1
      default/max_threads: 16
      default/allow_experimental_database_replicated: 1
    quotas:
      default/interval/duration: 3600
      default/interval/queries: 0
      default/interval/errors: 0
      default/interval/result_rows: 0
      default/interval/read_rows: 0
      default/interval/execution_time: 0
    users:
      #${CLICKHOUSE_ADMIN}/networks/ip: "::/0"
      ${CLICKHOUSE_ADMIN}/password: "${CLICKHOUSE_ADMIN_PASS}"
      ${CLICKHOUSE_USER}/networks/ip: "::/0"
      ${CLICKHOUSE_USER}/password: "${CLICKHOUSE_USER_PASS}"
      # Or
      # Generate password and the corresponding SHA256 hash with:
      # $ PASSWORD=\$(base64 < /dev/urandom | head -c8); echo "\$PASSWORD"; echo -n "\$PASSWORD" | sha256sum | tr -d '-'
      # 6edvj2+d                                                          <- first line is the password
      # a927723f4a42cccc50053e81bab1fcf579d8d8fb54a3ce559d42eb75a9118d65  <- second line is the corresponding SHA256 hash
      # clickhouse-user/password_sha256_hex: "a927723f4a42cccc50053e81bab1fcf579d8d8fb54a3ce559d42eb75a9118d65"
      # Or
      # Generate password and the corresponding SHA1 hash with:
      # $ PASSWORD=\$(base64 < /dev/urandom | head -c8); echo "\$PASSWORD"; echo -n "\$PASSWORD" | sha1sum | tr -d '-' | xxd -r -p | sha1sum | tr -d '-'
      # LJfoOfxl                                  <- first line is the password, put this in the k8s secret
      # 3435258e803cefaab7db2201d04bf50d439f6c7f  <- the corresponding double SHA1 hash, put this below
      # clickhouse-user/password_double_sha1_hex: "3435258e803cefaab7db2201d04bf50d439f6c7f"
  templates:
    podTemplates:
    - name: clickhouse
      spec:
        containers:
          - name: instana-clickhouse
            image: artifact-public.instana.io/self-hosted-images/k8s/clickhouse:23.3.10.5-1-lts-ibm_v0.29.0
            command:
              - clickhouse-server
              - --config-file=/etc/clickhouse-server/config.xml
            resources:
              limits:
                memory: 3Gi
              requests:
                cpu: "1"
                memory: 2Gi
          - name: clickhouse-log
            args:
            - while true; do sleep 30; done;
            command:
            - /bin/sh
            - -c
            - --
            image: registry.access.redhat.com/ubi9/ubi-minimal:latest
        imagePullSecrets:
          - name: clickhouse-image-secret
        ### FIX for K8s
        #  securityContext:
        #    fsGroup: 0
        #    runAsGroup: 0
        #    runAsUser: 1001
        #########
    volumeClaimTemplates:
      - name: instana-clickhouse-data-volume
        spec:
          accessModes:
            - ReadWriteOnce
          resources:
            requests:
              storage: 100Gi
          storageClassName: ${RWO_STORAGECLASS}
      - name: instana-clickhouse-log-volume
        spec:
          accessModes:
            - ReadWriteOnce
          resources:
            requests:
              storage: 1Gi
          storageClassName: ${RWO_STORAGECLASS}
    serviceTemplates:
      - name: service-template
        generateName: "clickhouse-{chi}"
        spec:
          ports:
            - name: http
              port: 8123
            - name: tcp
              port: 9000
          type: ClusterIP
EOF



cat << EOF > ${MANIFEST_FILENAME_BEEINSTANA}
apiVersion: beeinstana.instana.com/v1beta1
kind: BeeInstana
metadata:
  name: instance
  namespace: beeinstana
spec:
  ###### For OCP 4.11 and later
  # fsGroup: <GROUP_ID> # Will be set by install script
  seccompProfile:
    type: RuntimeDefault
  ######
  version: 1.4.0
  adminCredentials:
    secretName: beeinstana-admin-creds
  kafkaSettings:
    brokers:
      # Update KAFKA_NAMESPACE to the namespace where Kafka is installed
      - instana-kafka-bootstrap.instana-kafka:9092
    securityProtocol: SASL_PLAINTEXT
    saslMechanism: SCRAM-SHA-512
    saslPasswordCredential:
      secretName: beeinstana-kafka-creds
  config:
    cpu: 200m
    memory: 200Mi
    replicas: 1
  ingestor:
    cpu: 2
    memory: 2Gi
    limitMemory: true
    env: on-prem
    metricsTopic: raw_metrics
    replicas: 1
  aggregator:
    cpu: 2
    memory: 2Gi
    limitMemory: true
    mirrors: 1
    shards: 1
    volumes:
      live:
        size: 2000Gi
        # Uncomment the line below to specify your own storage class.
        storageClass: ${RWO_STORAGECLASS}
  # Should set useMultiArchImages to true for s390x and ppc64le
  useMultiArchImages: false
EOF


cat << EOF > ${MANIFEST_FILENAME_CORE}
apiVersion: instana.io/v1beta2
kind: Core
metadata:
  namespace: instana-core
  name: instana-core
spec:
  resourceProfile: small

  # Base domain for Instana
  baseDomain: ${INSTANA_BASE_DOMAIN}

  # Host and port for the agent acceptor, usually a subdomain of the base domain
  agentAcceptorConfig:
    host: ${INSTANA_AGENT_ACCEPTOR}
    port: 443

  # dockerRegistryURI: containers.instana.io
  imageConfig:
    registry: artifact-public.instana.io

  imagePullSecrets:
    - name: instana-registry

  # URL for downloading the GeoLite2 geo-location data file
  # geoDbUrl:

  properties:
    - name: retention.metrics.rollup5
      value: "86400"
    - name: retention.metrics.rollup60
      value: "2678400"
    - name: retention.metrics.rollup300
      value: "8035200"
    - name: retention.metrics.rollup3600
      value: "34214400"
    - name: config.appdata.shortterm.retention.days
      value: "7"
    - name: config.synthetics.retention.days
      value: "7"

  # Datastore configs
  datastoreConfigs:
    beeInstanaConfig:
      authEnabled: true
      clustered: true
      hosts:
      - aggregators.beeinstana.svc
      ports:
      - name: tcp
        port: 9998
    cassandraConfigs:
    - hosts:
      - instana-cassandra-service.instana-cassandra.svc
      datacenter: cassandra
      authEnabled: true
    clickhouseConfigs:
    - clusterName: local
      authEnabled: true
      hosts:
        - chi-instana-local-0-0.instana-clickhouse.svc
        - chi-instana-local-0-1.instana-clickhouse.svc
      # ports:
      #   - name: tcp
      #     port: 9000
      #   - name: http
      #     port: 8123
      # schemas:
      #   - application
      #   - logs
      #   - synthetics
    elasticsearchConfig:
      clusterName: instana
      defaultIndexReplicas: 0
      defaultIndexRoutingPartitionSize: 1
      defaultIndexShards: 1
      hosts:
      - instana-es-http.instana-elastic.svc
      authEnabled: true
    kafkaConfig:
      authEnabled: true
      hosts:
      - instana-kafka-bootstrap.instana-kafka.svc
      replicationFactor: 1
      saslMechanism: SCRAM-SHA-512
    postgresConfigs:
    - authEnabled: true
      #databases:
      #  - butlerdb
      #  - tenantdb
      #  - sales
      hosts:
        - postgres.instana-postgres.svc

  featureFlags:
    - name: beeinstana
      enabled: true
    - name: feature.beeinstana.enabled
      enabled: true
    - name: feature.beeinstana.infra.metrics.enabled
      enabled: true
    - name: feature.infra.explore.presentation.enabled
      enabled: true
    # - name: feature.infrastructure.explore.data.enabled
    #   enabled: true
    - name: feature.automation.enabled
      enabled: true
    - name: feature.infra.metrics.widget.enabled
      enabled: true
    # - name: feature.plugin.entity.metric.statistics.enabled
    #   enabled: true
    - name: feature.synthetics.enabled
      enabled: true
    - name: feature.synthetic.smart.alerts.enabled
      enabled: true
    - name: syntheticSmartAlertsEnabled
      enabled: true
    - name: feature.synthetic.create.test.advance.mode.enabled
      enabled: true
    - name: feature.synthetic.browser.create.test.enabled
      enabled: true
    - name: feature.synthetic.browser.script.enabled
      enabled: true
    - name: feature.vsphere.enabled
      enabled: false      
    - name: feature.automation.enabled
      enabled: true      
    - name: feature.action.automation.enabled
      enabled: true      
  # Use one of smtpConfig or sesConfig
  emailConfig:
    smtpConfig:
      check_server_identity: false
      from: test@example.com
      host: example.com
      port: 465
      startTLS: false
      useSSL: false

    # sesConfig:
    #   from:
    #   region:
    #   returnPath:
  
  operationMode: normal
  operationScopes:
  - core
  - global
  storageConfigs:
  #   Use either s3Config, gcloudConfig, or pvcConfig

    ## External Storage for raw spans ##
    rawSpans:
      pvcConfig:
        accessModes:
          - ReadWriteMany
        resources:
          requests:
            storage: 100Gi
        storageClassName: ${RWX_STORAGECLASS}
  
    synthetics:
      pvcConfig:
        accessModes:
          - ReadWriteMany
        resources:
          requests:
            storage: 50Gi
        storageClassName: ${RWX_STORAGECLASS}
        
    syntheticsKeystore:
      pvcConfig:
        accessModes:
          - ReadWriteMany
        resources:
          requests:
            storage: 10Gi
        storageClassName: ${RWX_STORAGECLASS}
        
  #     s3Config:
  #       bucket:
  #       bucketLongTerm:
  #       endpoint:
  #       prefix:
  #       prefixLongTerm:
  #       region:
  #       storageClass:
  #       storageClassLongTerm:
  #       accessKeyId:
  #       secretAccessKey:

  #     gcloudConfig:
  #       bucket:
  #       bucketLongTerm:
  #       prefix:
  #       prefixLongTerm:
  #       storageClass:
  #       storageClassLongTerm:
  #       serviceAccountKey:

  #     pvcConfig:
  #       accessModes:
  #         - ReadWriteMany
  #       resources:
  #         requests:
  #           storage: 100Gi
  #       storageClassName: my-fast-storage

    #   ## External Storage for synthetics test results ##
  #   synthetics:
  #     s3Config:
  #       bucket:
  #       bucketLongTerm:
  #       endpoint:
  #       prefix:
  #       prefixLongTerm:
  #       region:
  #       storageClass:
  #       storageClassLongTerm:
  #       accessKeyId:
  #       secretAccessKey:

  #     gcloudConfig:
  #       bucket:
  #       bucketLongTerm:
  #       prefix:
  #       prefixLongTerm:
  #       storageClass:
  #       storageClassLongTerm:
  #       serviceAccountKey:



  # Service provider configs for SAML or OIDC
  # serviceProviderConfig:
    # Base URL (defaults to "/auth")
    # basePath:

    # The maximum IDP metadata size (defaults to 200000)
    # maxAuthenticationLifetimeSeconds:

    # The maximum authentication lifetime (defaults to 604800)
    # maxIDPMetadataSizeInBytes:
EOF



cat << EOF > ${MANIFEST_FILENAME_UNIT}
apiVersion: instana.io/v1beta2
kind: Unit
metadata:
  namespace: instana-units
  name: ${INSTANA_TENANT_NAME}-${INSTANA_UNIT_NAME}
spec:
  # Must refer to the namespace of the associated Core object we created above
  coreName: instana-core

  # Must refer to the name of the associated Core object we created above
  coreNamespace: instana-core

  # The name of the tenant
  tenantName: ${INSTANA_TENANT_NAME}

  # The name of the unit within the tenant
  unitName: ${INSTANA_UNIT_NAME}

  # The same rules apply as for Cores. May be ommitted. Default is 'medium'
  resourceProfile: small
EOF



