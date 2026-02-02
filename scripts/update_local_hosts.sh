#!/bin/bash
set -e

ZONE_PARIS="europe-west9-b"
ZONE_NY="us-east1-b"
REGION_PARIS="europe-west9"
REGION_NY="us-east1"

# Infrastructure Hostnames (pointing to CP nodes)
HOST_PARIS="cp.paris.internal"
HOST_NY="cp.newyork.internal"

# Application Hostnames (pointing to Load Balancers)
# Paris
APP_PARIS="paris.demo.qws.xyz"
APP_PARIS_MCS="paris-mcs.demo.qws.xyz"
APP_PARIS_HEADLESS="paris-headless.demo.qws.xyz"
# New York
APP_NY="newyork.demo.qws.xyz"
APP_NY_MCS="newyork-mcs.demo.qws.xyz"
APP_NY_HEADLESS="newyork-headless.demo.qws.xyz"

echo "=== Fetching IPs from GCP ==="

# VM Public IPs
IP_CP_PARIS=$(gcloud compute instances describe cp-paris --zone $ZONE_PARIS --format='get(networkInterfaces[0].accessConfigs[0].natIP)')
IP_CP_NY=$(gcloud compute instances describe cp-newyork --zone $ZONE_NY --format='get(networkInterfaces[0].accessConfigs[0].natIP)')

# Load Balancer IPs
IP_LB_PARIS=$(gcloud compute forwarding-rules describe cilium-external-lb --region $REGION_PARIS --format='get(IPAddress)')
IP_LB_NY=$(gcloud compute forwarding-rules describe cilium-external-lb-newyork --region $REGION_NY --format='get(IPAddress)')

if [ -z "$IP_CP_PARIS" ] || [ -z "$IP_CP_NY" ] || [ -z "$IP_LB_PARIS" ] || [ -z "$IP_LB_NY" ]; then
    echo "Error: Could not fetch all IPs. Are the VMs and Load Balancers running?"
    exit 1
fi

echo "Found IPs:"
echo "  Paris CP:  $IP_CP_PARIS"
echo "  Paris LB:  $IP_LB_PARIS"
echo "  NY CP:     $IP_CP_NY"
echo "  NY LB:     $IP_LB_NY"

echo ""
echo "=== Updating /etc/hosts (requires sudo) ==="

# Define all hostnames to manage
ALL_HOSTS=(
    "$HOST_PARIS" "$HOST_NY"
    "$APP_PARIS" "$APP_PARIS_MCS" "$APP_PARIS_HEADLESS"
    "$APP_NY" "$APP_NY_MCS" "$APP_NY_HEADLESS"
)

# Remove old entries
for host in "${ALL_HOSTS[@]}"; do
    sudo sed -i "/$host/d" /etc/hosts
done

# Add new entries
echo "Adding Paris entries..."
echo "$IP_CP_PARIS $HOST_PARIS" | sudo tee -a /etc/hosts > /dev/null
echo "$IP_LB_PARIS $APP_PARIS" | sudo tee -a /etc/hosts > /dev/null
echo "$IP_LB_PARIS $APP_PARIS_MCS" | sudo tee -a /etc/hosts > /dev/null
echo "$IP_LB_PARIS $APP_PARIS_HEADLESS" | sudo tee -a /etc/hosts > /dev/null

echo "Adding New York entries..."
echo "$IP_CP_NY $HOST_NY" | sudo tee -a /etc/hosts > /dev/null
echo "$IP_LB_NY $APP_NY" | sudo tee -a /etc/hosts > /dev/null
echo "$IP_LB_NY $APP_NY_MCS" | sudo tee -a /etc/hosts > /dev/null
echo "$IP_LB_NY $APP_NY_HEADLESS" | sudo tee -a /etc/hosts > /dev/null

echo "/etc/hosts updated successfully."
echo "You can now access the apps on port 80:"
echo "  - Paris App: http://$APP_PARIS"
echo "  - NY App:    http://$APP_NY"
