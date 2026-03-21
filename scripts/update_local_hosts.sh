#!/bin/bash
set -e

ZONE_PARIS="europe-west9-b"
ZONE_AMS="us-east1-b"
REGION_PARIS="europe-west9"
REGION_AMS="us-east1"

# Infrastructure Hostnames (pointing to CP nodes)
HOST_PARIS="cp.paris.internal"
HOST_AMS="cp.amsterdam.internal"

# Application Hostnames (pointing to Load Balancers)
# Paris
APP_PARIS="paris.demo.qws.xyz"
APP_PARIS_MCS="paris-mcs.demo.qws.xyz"
APP_PARIS_HEADLESS="paris-headless.demo.qws.xyz"
# Amsterdam
APP_AMS="amsterdam.demo.qws.xyz"
APP_AMS_MCS="amsterdam-mcs.demo.qws.xyz"
APP_AMS_HEADLESS="amsterdam-headless.demo.qws.xyz"

echo "=== Fetching IPs from GCP ==="

# VM Public IPs
IP_CP_PARIS=$(gcloud compute instances describe cp-paris --zone $ZONE_PARIS --format='get(networkInterfaces[0].accessConfigs[0].natIP)')
IP_CP_AMS=$(gcloud compute instances describe cp-amsterdam --zone $ZONE_AMS --format='get(networkInterfaces[0].accessConfigs[0].natIP)')

# Load Balancer IPs
IP_LB_PARIS=$(gcloud compute forwarding-rules describe cilium-external-lb --region $REGION_PARIS --format='get(IPAddress)')
IP_LB_AMS=$(gcloud compute forwarding-rules describe cilium-external-lb-amsterdam --region $REGION_AMS --format='get(IPAddress)')

if [ -z "$IP_CP_PARIS" ] || [ -z "$IP_CP_AMS" ] || [ -z "$IP_LB_PARIS" ] || [ -z "$IP_LB_AMS" ]; then
    echo "Error: Could not fetch all IPs. Are the VMs and Load Balancers running?"
    exit 1
fi

echo "Found IPs:"
echo "  Paris CP:  $IP_CP_PARIS"
echo "  Paris LB:  $IP_LB_PARIS"
echo "  AMS CP:     $IP_CP_AMS"
echo "  AMS LB:     $IP_LB_AMS"

echo ""
echo "=== Updating /etc/hosts (requires sudo) ==="

# Define all hostnames to manage
ALL_HOSTS=(
    "$HOST_PARIS" "$HOST_AMS"
    "$APP_PARIS" "$APP_PARIS_MCS" "$APP_PARIS_HEADLESS"
    "$APP_AMS" "$APP_AMS_MCS" "$APP_AMS_HEADLESS"
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

echo "Adding Amsterdam entries..."
echo "$IP_CP_AMS $HOST_AMS" | sudo tee -a /etc/hosts > /dev/null
echo "$IP_LB_AMS $APP_AMS" | sudo tee -a /etc/hosts > /dev/null
echo "$IP_LB_AMS $APP_AMS_MCS" | sudo tee -a /etc/hosts > /dev/null
echo "$IP_LB_AMS $APP_AMS_HEADLESS" | sudo tee -a /etc/hosts > /dev/null

echo "/etc/hosts updated successfully."
echo "You can now access the apps on port 80:"
echo "  - Paris App: http://$APP_PARIS"
echo "  - AMS App:    http://$APP_AMS"
