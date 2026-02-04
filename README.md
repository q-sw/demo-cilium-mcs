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

### Step 3: Install Gateway API CRDs

> Install the standard Gateway API CRDs on both clusters.

```bash
make gateway-api-install
```

### Step 4: Export kubeconfig for both clusters

> this command downloads the  kubeconfig from each cluster and merges it into
> `~/.kube/config`, creating two contexts `paris` and `newyork`

```bash
make kubeconfig
```

### Step 5: Create CA for Cilium

> Create a CA certificate and key to sign all certificates in Cilium in both clusters

```bash
make certs-generate
```

> The script also creates a Kubernetes Secret `cilium-ca` in the `kube-system` namespace
> It also adds labels and annotations to be managed by Helm later

### Step 6: Add Cluster IP in `/etc/hosts`

```bash
make dns-local
```

## Initialize Cilium

> To be compatible with FluxCD the Helm Release name should follow the format
> `<namespace>-<release name>`. In our case, this is `kube-system-cilium`

### Initialize Cilium in Paris

```bash
helm upgrade --install kube-system-cilium cilium/cilium \
    --version 1.19.0-rc.0 --namespace kube-system --kube-context paris\
    -f init/cilium/values-paris.yaml
```

### Initialize Cilium in New York

```bash
helm upgrade --install kube-system-cilium cilium/cilium \
    --version 1.19.0-rc.0 --namespace kube-system --kube-context newyork\
    -f init/cilium/values-newyork.yaml
```

### Check Cilium status

```bash
cilium status
```

## Bootstrap FluxCD and Manage Cilium with FluxCD

### Step 1: Bootstrap FluxCD in the Paris Cluster

> You should have an SSH key pair allowed on GitHub

```bash
flux bootstrap git --url=ssh://git@github.com/${GITHUB_USERNAME}/${REPO_NAME}.git \
    --branch=main --path=flux/clusters/paris --private-key-file ${KEY_PATH} \
    --context paris
```

### Step 2: Bootstrap FluxCD in the New York Cluster

```bash
flux bootstrap git --url=ssh://git@github.com/${GITHUB_USERNAME}/${REPO_NAME}.git \
    --branch=main --path=flux/clusters/newyork --private-key-file ${KEY_PATH} \
    --context newyork
```

### Some commands to check FluxCD Status

```bash
flux get kustomizations
kubectl get kustomizations.kustomize.toolkit.fluxcd.io -A
kubectl get helmreleases.helm.toolkit.fluxcd.io -A
```

### Check Helm Values deployed by FluxCD

```bash
kubectl get helmrelease cilium -n flux-system -o yaml
```

## Verify Cluster Mesh and MCS API

> FluxCD has automatically configured the **Cilium Cluster Mesh**, enabled the **MCS-API**,
> and deployed the **test application** across both clusters.
> The following steps verify that the GitOps synchronization has successfully established the multi-cluster
> infrastructure.

### Step 1: Verify Cluster Mesh Status

```bash
cilium clustermesh status --context paris
cilium clustermesh status --context newyork
```

### Step 2: Verify MCS API Resources

Check ServiceExports and ServiceImports in both clusters.

```bash
kubectl get serviceexports --context paris
kubectl get serviceimports --context paris
```

### Step 3: Test Global DNS Resolution

From a pod in Paris, try to resolve the global service domain.

```bash
kubectl --context paris exec -it deploy/toolbox -- dig +short demo-app.default.svc.clusterset.local
```

### Step 4: Test Multi-Cluster Connectivity

Access the global service. Requests should be load-balanced between clusters.

```bash
for i in {1..10}; do
  kubectl --context paris exec deploy/toolbox -- curl -s demo-app.default.svc.clusterset.local/api | jq '.'
done
```

### Step 5: Verify Network Policies

Check the Cilium Network Policy that blocks ingress from New York.

```bash
kubectl get cnp deny-ingress-from-newyork --context paris
```

Test access from New York to Paris (should be blocked or timeout).

```bash
kubectl --context newyork exec deploy/toolbox -- curl --connect-timeout 2 -s demo-app.default.svc.clusterset.local/api
```

### Step 6: Observability with Hubble

Observe dropped traffic.

```bash
hubble observe --label app=demo-app --verdict DROPPED --type policy-verdict
```

## Verify Gateway API and UI Access

FluxCD has also configured a **Cilium Gateway API** (Layer 7 Load Balancer) in each cluster to expose the application UI
to the outside world.

### Step 0: Patch Gateway Services

Ensure the Gateway services are correctly patched with fixed NodePorts to match the `update_local_hosts` configuration.

```bash
make gateway-patch
```

### Step 1: Verify HTTPRoutes

Verify that the HTTPRoutes are correctly created and bound to the Gateways. These routes handle the traffic forwarding
to your services.

```bash
kubectl get httproute --context paris
kubectl get httproute --context newyork
```

### Step 2: Access the UI

Open your web browser and navigate to the URLs configured in your `/etc/hosts`.
You should see the "Cilium Multi-Cluster Demo" UI.

- **Paris Gateway:** [http://paris-mcs.demo.qws.xyz](http://paris-mcs.demo.qws.xyz)
- **New York Gateway:** [http://newyork-mcs.demo.qws.xyz](http://newyork-mcs.demo.qws.xyz)

The UI displays which pod (cluster and pod name) served the request. Refresh the page to see the load balancing in
action (if enabled) or how local traffic is prioritized.

> [!WARNING]
> **Network Policy Limitation with Gateway API**
> Currently, the `CiliumNetworkPolicy` demonstrated earlier **does not apply** to traffic entering via the Gateway API.
> Traffic from the Gateway is tagged as `ingress` or `world`, and at this stage, it is not possible to easily
> distinguish between the Gateway API of the local cluster and the Gateway API of the remote cluster solely based on
> identity labels. Therefore, external access via the Gateway remains allowed even if internal cross-cluster traffic is
> restricted.

## Demo

### Demo Part 1

![demo_part1](docs/demo_part1.gif)

### Demo Part 2

![demo_part2](docs/demo_part2.gif)
