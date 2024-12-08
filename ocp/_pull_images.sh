#!/bin/bash

echo "Reading credentials.env"
source ../credentials.env
source ../artefacts.env

podman login artifact-public.instana.io -u _ -p ${DOWNLOAD_KEY}

## Cassandra
podman pull artifact-public.instana.io/self-hosted-images/3rd-party/operator/cass-operator:1.22.4_v0.17.0
podman pull artifact-public.instana.io/self-hosted-images/3rd-party/datastore/system-logger:1.22.4_v0.6.0
podman pull artifact-public.instana.io/self-hosted-images/3rd-party/datastore/k8ssandra-client:0.6.0_v0.7.0
podman pull artifact-public.instana.io/self-hosted-images/3rd-party/datastore/cassandra:4.1.4_v0.18.0

## Zookeeper
podman pull artifact-public.instana.io/self-hosted-images/3rd-party/operator/zookeeper:0.2.15_v0.13.0
podman pull artifact-public.instana.io/self-hosted-images/3rd-party/datastore/zookeeper:3.8.4_v0.14.0
podman pull artifact-public.instana.io/self-hosted-images/k8s/kubectl:v1.31.0_v0.1.0

## Clickhouse
podman pull artifact-public.instana.io/clickhouse-operator:v1.2.0
podman pull artifact-public.instana.io/clickhouse-openssl:23.8.10.43-1-lts-ibm

## Elasticsearch
podman pull artifact-public.instana.io/self-hosted-images/3rd-party/operator/elasticsearch:2.14.0_v0.14.0
podman pull artifact-public.instana.io/self-hosted-images/3rd-party/datastore/elasticsearch:7.17.24_v0.11.0

## Kafka
podman pull artifact-public.instana.io/self-hosted-images/3rd-party/operator/strimzi:0.42.0_v0.12.0
podman pull artifact-public.instana.io/self-hosted-images/3rd-party/datastore/kafka:0.42.0-kafka-3.7.1_v0.11.0

## Postgres
podman pull artifact-public.instana.io/self-hosted-images/3rd-party/operator/cloudnative-pg:v1.21.1_v0.7.0
podman pull artifact-public.instana.io/self-hosted-images/3rd-party/datastore/cnpg-containers:15_v0.9.0

## Beeinstana
podman pull --platform linux/amd64 artifact-public.instana.io/beeinstana/operator:v1.61.0
podman pull --platform linux/amd64 artifact-public.instana.io/beeinstana/aggregator:v1.85.36-release
podman pull --platform linux/amd64 artifact-public.instana.io/beeinstana/monconfig:v2.19.0
podman pull --platform linux/amd64 artifact-public.instana.io/beeinstana/ingestor:v1.85.36-release

## Instana backend
podman pull artifact-public.instana.io/backend/acceptor:3.285.627-0
podman pull artifact-public.instana.io/backend/accountant:3.285.627-0
podman pull artifact-public.instana.io/backend/action-orchestration:3.285.627-0
podman pull artifact-public.instana.io/backend/action-reader:3.285.627-0
podman pull artifact-public.instana.io/backend/action-writer:3.285.627-0
podman pull artifact-public.instana.io/backend/appdata-health-aggregator:3.285.627-0
podman pull artifact-public.instana.io/backend/appdata-health-processor:3.285.627-0
podman pull artifact-public.instana.io/backend/appdata-legacy-converter:3.285.627-0
podman pull artifact-public.instana.io/backend/appdata-live-aggregator:3.285.627-0
podman pull artifact-public.instana.io/backend/appdata-processor:3.285.627-0
podman pull artifact-public.instana.io/backend/appdata-reader:3.285.627-0
podman pull artifact-public.instana.io/backend/appdata-writer:3.285.627-0
podman pull artifact-public.instana.io/backend/bizops-reader:3.285.627-0
podman pull artifact-public.instana.io/backend/bizops-writer:3.285.627-0
podman pull artifact-public.instana.io/backend/butler:3.285.627-0
podman pull artifact-public.instana.io/backend/cashier-ingest:3.285.627-0
podman pull artifact-public.instana.io/backend/cashier-rollup:3.285.627-0
podman pull artifact-public.instana.io/backend/collaborations-helper:3.285.627-0
podman pull artifact-public.instana.io/backend/email-health-provider:3.285.627-0
podman pull artifact-public.instana.io/backend/eum-acceptor:3.285.627-0
podman pull artifact-public.instana.io/backend/eum-health-processor:3.285.627-0
podman pull artifact-public.instana.io/backend/eum-processor:3.285.627-0
podman pull artifact-public.instana.io/backend/filler:3.285.627-0
podman pull artifact-public.instana.io/backend/gateway:1.25.1_v0.43.0
podman pull artifact-public.instana.io/backend/groundskeeper:3.285.627-0
podman pull artifact-public.instana.io/backend/infra-health-processor:3.285.627-0
podman pull artifact-public.instana.io/backend/infra-metric-aggregator:3.285.627-0
podman pull artifact-public.instana.io/backend/issue-tracker:3.285.627-0
podman pull artifact-public.instana.io/backend/js-stack-trace-translator:3.285.627-0
podman pull artifact-public.instana.io/backend/log-health-processor:3.285.627-0
podman pull artifact-public.instana.io/backend/log-processor:3.285.627-0
podman pull artifact-public.instana.io/backend/log-reader:3.285.627-0
podman pull artifact-public.instana.io/backend/log-writer:3.285.627-0
podman pull artifact-public.instana.io/backend/otlp-acceptor:3.285.627-0
podman pull artifact-public.instana.io/backend/processor:3.285.627-0
podman pull artifact-public.instana.io/backend/serverless-acceptor:3.285.627-0
podman pull artifact-public.instana.io/backend/sli-beacons-filter:3.285.627-0
podman pull artifact-public.instana.io/backend/sli-calls-filter:3.285.627-0
podman pull artifact-public.instana.io/backend/sli-data-reader:3.285.627-0
podman pull artifact-public.instana.io/backend/sli-data-writer:3.285.627-0
podman pull artifact-public.instana.io/backend/sli-evaluator:3.285.627-0
podman pull artifact-public.instana.io/backend/sli-health-processor:3.285.627-0
podman pull artifact-public.instana.io/backend/synthetics-acceptor:3.285.627-0
podman pull artifact-public.instana.io/backend/synthetics-health-processor:3.285.627-0
podman pull artifact-public.instana.io/backend/synthetics-reader:3.285.627-0
podman pull artifact-public.instana.io/backend/synthetics-writer:3.285.627-0
podman pull artifact-public.instana.io/backend/tag-processor:3.285.627-0
podman pull artifact-public.instana.io/backend/tag-reader:3.285.627-0
podman pull artifact-public.instana.io/backend/ui-backend:3.285.627-0
podman pull artifact-public.instana.io/backend/ui-client:3.285.627-0
podman pull artifact-public.instana.io/backend/config-templates:3.285.627-0
podman pull artifact-public.instana.io/infrastructure/instana-enterprise-operator:1.1.1
