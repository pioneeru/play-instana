#!/bin/bash

echo "Reading credentials.env"
source ../credentials.env
source ../artifacts-${INSTANA_PLATFORM}.env

read_template() {
eval "cat <<EOF
$(<$1)
EOF
"
}

normalize_merged_yaml_arrays() {
    idPath=$1  originalPath=$2  otherPath=$2 yq eval-all '
    (
    (( (eval(strenv(originalPath)) + eval(strenv(otherPath) )) | .[] | {(eval(strenv(idPath))):  .}) as $item ireduce ({}; . * $item )) as $uniqueMap
    | ( $uniqueMap  | to_entries | .[]) as $item ireduce([]; . + $item.value)
    ) as $mergedArray
    | select(fi == 0) | (eval(strenv(originalPath))) = $mergedArray
    ' $4
}

for FILE in templates/*; do
    FILENAME=$(basename "$FILE")
    echo "Generating file: ${FILENAME}"
    read_template $file > temp.yaml
    if [ -f "${CUSTOM_CONFIGS_FOLDER}/${FILENAME}" ]; then
        # Merge yamls
        yq eval-all '. as $item ireduce ({}; . *+ $item)' temp.yaml ${CUSTOM_CONFIGS_FOLDER}/${FILENAME} > temp-merged.yaml
        # Merge same array items in the yaml
        case ${FILENAME} in
            clickhouse.yaml|clickhouse_keeper.yaml)
                normalize_merged_yaml_arrays ".name" ".spec.templates.podTemplates" "temp-merged.yaml" > ${FILENAME}
                ;;
            elasticsearch.yaml)
                normalize_merged_yaml_arrays ".name" ".spec.nodeSets" "temp-merged.yaml" > ${FILENAME}
                ;;
            kafka-users.yaml)
                normalize_merged_yaml_arrays ".resource.type" ".spec.authorization.acls" "temp-merged.yaml" > ${FILENAME}
                ;;
            kafka.yaml)
                normalize_merged_yaml_arrays ".name" ".spec.kafka.listeners" "temp-merged.yaml" > ${FILENAME}
                ;;
            postgresql.yaml)
                normalize_merged_yaml_arrays ".name" ".spec.managed.roles" "temp-merged.yaml" > ${FILENAME}
                ;;
            core.yaml)
                normalize_merged_yaml_arrays ".name" ".spec.properties" "temp-merged.yaml" > temp-merged1.yaml
                normalize_merged_yaml_arrays ".name" ".spec.featureFlags" "temp-merged1.yaml" > temp-merged.yaml
                normalize_merged_yaml_arrays ".name" ".spec.componentConfigs" "temp-merged.yaml" > ${FILENAME}
                ;;
            unit.yaml)
                normalize_merged_yaml_arrays ".name" ".spec.properties" "temp-merged.yaml" > temp-merged1.yaml
                normalize_merged_yaml_arrays ".name" ".spec.componentConfigs" "temp-merged1.yaml" > ${FILENAME}
                ;;
            *)
                mv temp-merged.yaml ${FILENAME}
                ;;
        esac
    else
        mv temp.yaml ${FILENAME}
    fi
done
rm -f temp-merged1.yaml temp-merged.yaml temp.yaml



# eval "cat <<EOF
# $(<templates/kafka.yaml)
# EOF
# " > ${MANIFEST_FILENAME_KAFKA}



# eval "cat <<EOF
# $(<templates/kafka-rebalance.yaml)
# EOF
# " > kafka-rebalance.yaml



# eval "cat <<EOF
# $(<templates/elasticsearch.yaml)
# EOF
# " > ${MANIFEST_FILENAME_ELASTICSEARCH}



# eval "cat <<EOF
# $(<templates/postgresql.yaml)
# EOF
# " > ${MANIFEST_FILENAME_POSTGRES}



# eval "cat <<EOF
# $(<templates/cassandra-scc.yaml)
# EOF
# " > ${MANIFEST_FILENAME_CASSANDRA_SCC}

# eval "cat <<EOF
# $(<templates/cassandra.yaml)
# EOF
# " > ${MANIFEST_FILENAME_CASSANDRA}



# eval "cat <<EOF
# $(<templates/clickhouse-scc.yaml)
# EOF
# " > ${MANIFEST_FILENAME_CLICKHOUSE_SCC}

# eval "cat <<EOF
# $(<templates/clickhouse_keeper.yaml)
# EOF
# " > ${MANIFEST_FILENAME_CLICKHOUSE_KEEPER}

# eval "cat <<EOF
# $(<templates/clickhouse.yaml)
# EOF
# " > ${MANIFEST_FILENAME_CLICKHOUSE}




# eval "cat <<EOF
# $(<templates/beeinstana.yaml)
# EOF
# " > ${MANIFEST_FILENAME_BEEINSTANA}




# eval "cat <<EOF
# $(<templates/core.yaml)
# EOF
# " > ${MANIFEST_FILENAME_CORE}



# eval "cat <<EOF
# $(<templates/unit.yaml)
# EOF
# " > ${MANIFEST_FILENAME_UNIT}

