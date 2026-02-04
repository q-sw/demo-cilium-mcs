#!/bin/bash

# Configuration
TYPE_SPEED=20
WAIT_BETWEEN_COMMANDS=2
GIT_URL="ssh://git@github.com/q-sw/demo-cilium-mcs.git"
CILIUM_VERSION="1.19.0-rc.0"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

pe() {
    local cmd="$1"
    echo -ne "${BLUE}$ ${NC}"
    for ((i = 0; i < ${#cmd}; i++)); do
        echo -n "${cmd:$i:1}"
        sleep "$(awk -v ts=$TYPE_SPEED 'BEGIN{srand(); print (rand()*ts+10)/1000}')"
    done
    echo ""
    eval "$cmd"
    echo ""
    sleep $WAIT_BETWEEN_COMMANDS
}

marker() {
    echo "::MARKER::$1::"
}

clear
echo -e "${GREEN}=== DEMO PART 1: CILIUM INSTALLATION & FLUXCD BOOTSTRAP ===${NC}"
echo ""

# 1. Initial state (Nodes without CNI)
marker "Initial State"
echo -e "${YELLOW}# Observing initial cluster state (CNI not installed)${NC}"
pe "kubectl get nodes --context paris"
pe "kubectl get pods -n kube-system --context paris"
pe "kubectl get nodes --context newyork"
pe "kubectl get pods -n kube-system --context newyork"

# 2. Installing Cilium via Helm
marker "Cilium Installation (Paris)"
echo -e "${YELLOW}# Installing Cilium on Paris cluster via Helm${NC}"
pe "helm upgrade --install kube-system-cilium cilium/cilium --version $CILIUM_VERSION --namespace kube-system --kube-context paris -f init/cilium/values-paris.yaml"

marker "Cilium Installation (New York)"
echo -e "${YELLOW}# Installing Cilium on New York cluster via Helm${NC}"
pe "helm upgrade --install kube-system-cilium cilium/cilium --version $CILIUM_VERSION --namespace kube-system --kube-context newyork -f init/cilium/values-newyork.yaml"

# 3. Verifying Cilium status
marker "Cilium Verification"
echo -e "${YELLOW}# Waiting for Cilium 'Ready' status${NC}"
pe "cilium status --context paris --wait"
pe "cilium status --context newyork --wait"

# 4. FluxCD Enrollment (Bootstrap)
marker "FluxCD Bootstrap (Paris)"
echo -e "${YELLOW}# Initializing FluxCD (GitOps) on Paris cluster${NC}"
pe "flux bootstrap git --url=$GIT_URL --branch=main --path=flux/clusters/paris --context=paris --private-key-file ${HOME}/.ssh/id_ecdsa --silent"

marker "FluxCD Bootstrap (New York)"
echo -e "${YELLOW}# Initializing FluxCD (GitOps) on New York cluster${NC}"
pe "flux bootstrap git --url=$GIT_URL --branch=main --path=flux/clusters/newyork --context=newyork --private-key-file ${HOME}/.ssh/id_ecdsa --silent"

# 5. Verification
marker "Flux Synchronization"
echo -e "${YELLOW}# Verifying Flux synchronization${NC}"
pe "flux get kustomizations --context paris"
pe "flux get kustomizations --context newyork"
