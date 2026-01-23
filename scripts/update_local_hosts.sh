#!/bin/bash
set -e

ZONE_PARIS="europe-west9-b"
ZONE_NY="us-east1-b"
HOST_PARIS="cp.paris.internal"
HOST_NY="cp.newyork.internal"

echo "=== Fetching Public IPs from GCP ==="
IP_PARIS=$(gcloud compute instances describe cp-paris --zone $ZONE_PARIS --format='get(networkInterfaces[0].accessConfigs[0].natIP)')
IP_NY=$(gcloud compute instances describe cp-newyork --zone $ZONE_NY --format='get(networkInterfaces[0].accessConfigs[0].natIP)')

if [ -z "$IP_PARIS" ] || [ -z "$IP_NY" ]; then
    echo "Error: Could not fetch IPs. Are the VMs running?"
    exit 1
fi

echo "Found IPs:"
echo "  $HOST_PARIS -> $IP_PARIS"
echo "  $HOST_NY -> $IP_NY"

echo ""
echo "=== Updating /etc/hosts (requires sudo) ==="

# Remove old entries
sudo sed -i "/$HOST_PARIS/d" /etc/hosts
sudo sed -i "/$HOST_NY/d" /etc/hosts

# Add new entries
echo "$IP_PARIS $HOST_PARIS" | sudo tee -a /etc/hosts > /dev/null
echo "$IP_NY $HOST_NY" | sudo tee -a /etc/hosts > /dev/null

echo "/etc/hosts updated successfully."
