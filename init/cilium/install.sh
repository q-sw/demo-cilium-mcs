#!/bin/bash
set -e

# Configuration
CILIUM_VERSION="1.19.1"
CTX_PARIS="paris"
CTX_AMS="amsterdam"

echo "=== Adding Cilium Helm Repo ==="
helm repo add cilium https://helm.cilium.io/
helm repo update

echo "=== Installing Cilium on Paris ==="
helm upgrade --install kube-system-cilium cilium/cilium --version $CILIUM_VERSION \
    --namespace kube-system \
    --kube-context $CTX_PARIS \
    -f values-paris.yaml

echo "=== Installing Cilium on Amsterdam ==="
helm upgrade --install kube-system-cilium cilium/cilium --version $CILIUM_VERSION \
    --namespace kube-system \
    --kube-context $CTX_AMS \
    -f values-amsterdam.yaml

echo "=== Waiting for Cilium to be ready ==="
cilium status --context $CTX_PARIS --wait
cilium status --context $CTX_AMS --wait

#echo "=== Connecting Clusters (Cluster Mesh) ==="
#cilium clustermesh connect \
#    --context $CTX_PARIS \
#    --destination-context $CTX_AMS
#
#echo "=== Verifying Connectivity ==="
#cilium connectivity test --context $CTX_PARIS --multi-cluster $CTX_AMS
