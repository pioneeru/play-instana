#!/bin/bash

echo "Reading credentials.env..."
source ../credentials.env

### Units
echo "Deleteing unit..."
${KUBECTL} -n instana-units delete unit `${KUBECTL} -n instana-units get unit -o jsonpath='{.items[0].metadata.name}'` --wait=false
echo "Waiting for Unit pods deletion..."
${KUBECTL} -n instana-units wait --for=delete pod --all --timeout=3000s

### Core
echo "Deleteing core..."
${KUBECTL} -n instana-core delete core instana-core --wait=false
echo "Waiting for Core pods deletion..."
${KUBECTL} -n instana-core wait --for=delete pod --all --timeout=3000s


echo "Uninstaling instana operator..."
${KUBECTL} instana operator template --namespace instana-operator --output-dir tempinstoper
${KUBECTL} delete -f tempinstoper
rm -rf tempinstoper


echo "Deleting instana-units namespace..."
${KUBECTL} delete ns instana-units 
echo "Deleting instana-core namespace..."
${KUBECTL} delete ns instana-core 
echo "Deleting instana-operator namespace..."
${KUBECTL} delete ns instana-operator 

echo "Done."
