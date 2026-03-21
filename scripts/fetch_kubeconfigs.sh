#!/bin/bash
set -e

# Variables
ZONE_PARIS="europe-west9-b"
ZONE_AMS="europe-west4-b"

echo "=== Fetching Kubeconfig from Paris ==="
gcloud compute ssh ubuntu@cp-paris --zone $ZONE_PARIS --tunnel-through-iap --command "sudo cp /etc/kubernetes/admin.conf /tmp/paris.conf && sudo chmod 644 /tmp/paris.conf"
gcloud compute scp ubuntu@cp-paris:/tmp/paris.conf ./paris.conf --zone $ZONE_PARIS --tunnel-through-iap

sed -i 's/kubernetes-admin@kubernetes/admin-paris@paris/g' paris.conf

sed -i 's/kubernetes/paris/g' paris.conf

echo "=== Fetching Kubeconfig from Amsterdam ==="

gcloud compute ssh ubuntu@cp-amsterdam --zone $ZONE_AMS --tunnel-through-iap --command "sudo cp /etc/kubernetes/admin.conf /tmp/amsterdam.conf && sudo chmod 644 /tmp/amsterdam.conf"

gcloud compute scp ubuntu@cp-amsterdam:/tmp/amsterdam.conf ./amsterdam.conf --zone $ZONE_AMS --tunnel-through-iap

sed -i 's/kubernetes-admin@kubernetes/admin-amsterdam@amsterdam/g' amsterdam.conf

sed -i 's/kubernetes/amsterdam/g' amsterdam.conf

echo "=== Merging Kubeconfigs ==="
# Backup
cp ~/.kube/config ~/.kube/config.bak."$(date +%F_%T)"
rm ~/.kube/config
touch ~/.kube/config

# Merge
KUBECONFIG=~/.kube/config:./paris.conf:./amsterdam.conf kubectl config view --flatten >~/.kube/config_merged
mv ~/.kube/config_merged ~/.kube/config

# Cleanup
#rm paris.conf amsterdam.conf

echo "Done. Contexts 'admin-paris@paris' and 'admin-amsterdam@amsterdam' created."
echo "Renaming contexts to 'paris' and 'amsterdam' for simplicity..."
kubectl config rename-context admin-paris@paris paris
kubectl config rename-context admin-amsterdam@amsterdam amsterdam

echo "Test with: kubectl get nodes --context paris"
