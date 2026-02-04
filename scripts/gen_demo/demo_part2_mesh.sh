#!/bin/bash

# Configuration
TYPE_SPEED=20
WAIT_BETWEEN_COMMANDS=2

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
echo -e "${GREEN}=== DEMO PART 2: CILIUM CLUSTER MESH & SECURITY ===${NC}"
echo ""
marker "Flux Synchronization"
echo -e "${YELLOW}# Verifying Flux synchronization${NC}"
pe "flux get kustomizations --context paris"
pe "flux get kustomizations --context newyork"

# 1. Cluster Mesh status verification
marker "Cluster Mesh Verification"
echo -e "${YELLOW}# Checking cluster interconnection${NC}"
pe "cilium clustermesh status --context paris"
pe "cilium clustermesh status --context newyork"

# 2. MCS API ServiceExports verification
marker "MCS API Resources"
echo -e "${YELLOW}# Observing MCS API resources (Multi-Cluster Service)${NC}"
pe "kubectl get service --context paris"
pe "kubectl get serviceexports --context paris"
pe "kubectl get serviceimports --context paris"
echo ""
pe "kubectl get service --context newyork"
pe "kubectl get serviceexports --context newyork"
pe "kubectl get serviceimports --context newyork"

# 3. DNS resolution test for Clusterset (Paris -> Global)
marker "Global DNS Resolution"
echo -e "${YELLOW}# Testing global DNS resolution (.clusterset.local)${NC}"
pe "kubectl --context paris exec -it deploy/toolbox -- dig +short demo-app.default.svc.clusterset.local"

# 4. Connectivity test (using JSON API)
marker "Multi-Cluster Connectivity"
echo -e "${YELLOW}# Accessing global service via JSON API (balanced between Paris and NY)${NC}"
pe "for i in {1..10};do kubectl --context paris exec deploy/toolbox -- curl --connect-timeout 2 -s demo-app.default.svc.clusterset.local/api | jq '.'; done "

# 5. CiliumNetworkPolicy demonstration
marker "Network Policy"
echo -e "${YELLOW}# Verifying Network Policy (Blocking New York -> Paris)${NC}"
pe "kubectl get cnp deny-ingress-from-newyork --context paris -o yaml"

# 6. Blocked access test
marker "Blocking Test"
echo -e "${YELLOW}# Attempting access from New York to Paris (should fail)${NC}"
# shellcheck disable=SC2016
pe 'for i in {1..10}; do if output=$(kubectl --context newyork exec deploy/toolbox -- curl --connect-timeout 1 -s demo-app.default.svc.clusterset.local/api 2>/dev/null); then echo "$output" | jq "."; else echo "ACCESS BLOCKED BY NETWORK POLICY"; fi; done '

# 7. Hubble visualization
marker "Hubble Observability"
echo -e "${YELLOW}# Observing dropped traffic via Hubble${NC}"
hubble observe --label app=demo-app --verdict DROPPED --type policy-verdict -o table

echo ""
