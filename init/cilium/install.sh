#!/bin/bash
set -e

# Configuration
CILIUM_VERSION="1.19.0-rc.0"
CTX_PARIS="paris"
CTX_NY="newyork"

echo "=== Adding Cilium Helm Repo ==="
helm repo add cilium https://helm.cilium.io/
helm repo update

echo "=== Installing Cilium on Paris ==="
helm upgrade --install kube-system-cilium cilium/cilium --version $CILIUM_VERSION \
    --namespace kube-system \
    --kube-context $CTX_PARIS \
    -f values-common.yaml -f values-paris.yaml

echo "=== Installing Cilium on New York ==="
helm upgrade --install kube-system-cilium cilium/cilium --version $CILIUM_VERSION \
    --namespace kube-system \
    --kube-context $CTX_NY \
    -f values-common.yaml -f values-newyork.yaml

echo "=== Waiting for Cilium to be ready ==="
cilium status --context $CTX_PARIS --wait
cilium status --context $CTX_NY --wait

#echo "=== Connecting Clusters (Cluster Mesh) ==="
## Cette commande échange les CA et secrets entre les clusters
#cilium clustermesh connect \
#    --context $CTX_PARIS \
#    --destination-context $CTX_NY
#
#echo "=== Verifying Connectivity ==="
#cilium connectivity test --context $CTX_PARIS --multi-cluster $CTX_NY
