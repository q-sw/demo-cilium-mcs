# Demo-cilium-mcs

> Configure and Manage Cilium MCS-API with FluxCD

## Requirements

- GCP Account
- Terraform
- Ansible
- Cilium CLI
- FluxCD CLI
- Kubectl

## Build and configure Kubernetes Clusters (`paris` and `newyork`)

### Step 1: Create the infrastructure for 2 Kubernetes Clusters

```bash
make infra-create
```

### Step 2: Install Kubernetes with ansible and Kubeadm

```bash
make  k8s-install
```

### Step 3: Export kubeconfig for both clusters

> this command downloads the  kubeconfig from each cluster and merges it into
> `~/.kube/config`, creating two contexts `paris` and `newyork`

```bash
make kubeconfig
```

### Step 4: Create CA for Cilium

> Create a CA certificate and key to sign all certificates in Cilium in both clusters

```bash
make certs-generate
```

> The script also creates a Kubernetes Secret `cilium-ca` in the `kube-system` namespace
> It also adds labels and annotations to be managed by Helm later

### Step 5: Add Cluster IP in `/etc/hosts`

```bash
make dns-local
```

## Initialize Cilium

> To be compatible with FluxCD the Helm Release name should follow the format
> `<namespace>-<release name>`. In our case, this is `kube-system-cilium`

### Initialize Cilium in Paris

```bash
helm upgrade --install kube-system-cilium cilium/cilium \
    --version 1.19.0-rc.0 --namespace kube-system --context paris\
    -f init/cilium/values-paris.yaml
```

### Initialize Cilium in New York

```bash
helm upgrade --install kube-system-cilium cilium/cilium \
    --version 1.19.0-rc.0 --namespace kube-system --context newyork\
    -f init/cilium/values-newyork.yaml
```

### Check Cilium status

```bash
cilium status
```
