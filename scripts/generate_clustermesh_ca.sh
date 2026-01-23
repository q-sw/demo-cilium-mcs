#!/bin/bash
set -e

# Configuration
OUTPUT_DIR="init/cilium/certs"
CA_CN="Cilium Cluster Mesh CA"
CA_ALGO="ecdsa"
CA_SIZE=256

# Verification des dependances
if ! command -v cfssl &>/dev/null || ! command -v cfssljson &>/dev/null; then
    echo "Erreur: 'cfssl' et 'cfssljson' sont requis."
    echo "   Installation (Linux):"
    echo "   curl -L https://github.com/cloudflare/cfssl/releases/download/v1.6.4/cfssl_1.6.4_linux_amd64 -o /usr/local/bin/cfssl"
    echo "   curl -L https://github.com/cloudflare/cfssl/releases/download/v1.6.4/cfssljson_1.6.4_linux_amd64 -o /usr/local/bin/cfssljson"
    echo "   chmod +x /usr/local/bin/cfssl /usr/local/bin/cfssljson"
    exit 1
fi

echo "=== Generation du CA Cilium Cluster Mesh ==="
mkdir -p "$OUTPUT_DIR"
cd "$OUTPUT_DIR"

# Creation du CSR (Certificate Signing Request)
cat <<EOF >ca-csr.json
{
  "CN": "${CA_CN}",
  "key": {
    "algo": "${CA_ALGO}",
    "size": ${CA_SIZE}
  },
  "names": [
    {
      "O": "Cilium",
      "OU": "Cluster Mesh"
    }
  ]
}
EOF

# Generation du certificat et de la cle
echo "Generating CA in $OUTPUT_DIR..."
cfssl gencert -initca ca-csr.json | cfssljson -bare ca

# Nettoyage
rm ca-csr.json ca.csr

echo "CA genere avec succes :"
ls -l ca.pem ca-key.pem

echo ""
echo "=== Instructions pour l'installation ==="
echo ""
echo "# Cluster Paris"
pwd
kubectl create secret generic cilium-ca \
    --from-file=ca.crt=ca.pem \
    --from-file=ca.key=ca-key.pem \
    -n kube-system --context paris --dry-run=client -o yaml | kubectl apply --context paris -f - &&
    kubectl label secret cilium-ca -n kube-system --context paris app.kubernetes.io/managed-by=Helm --overwrite &&
    kubectl annotate secret cilium-ca -n kube-system --context paris meta.helm.sh/release-name=kube-system-cilium --overwrite &&
    kubectl annotate secret cilium-ca -n kube-system --context paris meta.helm.sh/release-namespace=kube-system --overwrite
echo ""
echo "# Cluster New York"
kubectl create secret generic cilium-ca \
    --from-file=ca.crt=ca.pem \
    --from-file=ca.key=ca-key.pem \
    -n kube-system --context newyork --dry-run=client -o yaml |
    kubectl apply --context newyork -f - &&
    kubectl label secret cilium-ca -n kube-system --context newyork app.kubernetes.io/managed-by=Helm --overwrite &&
    kubectl annotate secret cilium-ca -n kube-system --context newyork meta.helm.sh/release-name=kube-system-cilium --overwrite &&
    kubectl annotate secret cilium-ca -n kube-system --context newyork meta.helm.sh/release-namespace=kube-system --overwrite
