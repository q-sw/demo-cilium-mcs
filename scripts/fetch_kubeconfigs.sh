#!/bin/bash
set -e

# Variables
ZONE_PARIS="europe-west9-b"
ZONE_NY="us-east1-b"

echo "=== Fetching Kubeconfig from Paris ==="
gcloud compute ssh ubuntu@cp-paris --zone $ZONE_PARIS --tunnel-through-iap --command "sudo cp /etc/kubernetes/admin.conf /tmp/paris.conf && sudo chmod 644 /tmp/paris.conf"
gcloud compute scp ubuntu@cp-paris:/tmp/paris.conf ./paris.conf --zone $ZONE_PARIS --tunnel-through-iap

sed -i 's/kubernetes-admin@kubernetes/admin-paris@paris/g' paris.conf

sed -i 's/kubernetes/paris/g' paris.conf

echo "=== Fetching Kubeconfig from New York ==="

gcloud compute ssh ubuntu@cp-newyork --zone $ZONE_NY --tunnel-through-iap --command "sudo cp /etc/kubernetes/admin.conf /tmp/newyork.conf && sudo chmod 644 /tmp/newyork.conf"

gcloud compute scp ubuntu@cp-newyork:/tmp/newyork.conf ./newyork.conf --zone $ZONE_NY --tunnel-through-iap

sed -i 's/kubernetes-admin@kubernetes/admin-newyork@newyork/g' newyork.conf

sed -i 's/kubernetes/newyork/g' newyork.conf

echo "=== Merging Kubeconfigs ==="
# Backup
cp ~/.kube/config ~/.kube/config.bak."$(date +%F_%T)"
rm ~/.kube/config
touch ~/.kube/config

# Merge
KUBECONFIG=~/.kube/config:./paris.conf:./newyork.conf kubectl config view --flatten >~/.kube/config_merged
mv ~/.kube/config_merged ~/.kube/config

# Cleanup
#rm paris.conf newyork.conf

echo "Done. Contexts 'admin-paris@paris' and 'admin-newyork@newyork' created."
echo "Renaming contexts to 'paris' and 'newyork' for simplicity..."
kubectl config rename-context admin-paris@paris paris
kubectl config rename-context admin-newyork@newyork newyork

echo "Test with: kubectl get nodes --context paris"
