.PHONY: help infra-init infra-create infra-destroy k8s-install kubeconfig cilium-install app-build app-deploy-global app-deploy-mcs setup-all setup-dns-local

# Variables
PROJECT_ID ?= $(shell gcloud config get-value project)
IMAGE_NAME ?= europe-west9-docker.pkg.dev/qsw-main/qsw-docker/mcs-demo:latest

help:
	@printf "Available targets:\n"
	@grep -E '^[1-9a-zA-Z_-]+:.*?## .*$$|(^#--)' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[32m %-43s\033[0m %s\n", $$1, $$2}' \
		| sed -e 's/\[32m #-- /[33m/'

default: help

#-- Infrastructure (Terraform) --

infra-init: ## Initialize Terraform
	cd init/terraform && terraform init

infra-create: infra-init ## Create GCP infrastructure (VPC, VMs)
	cd init/terraform && terraform apply -var="project_id=$(PROJECT_ID)" -auto-approve

infra-destroy: ## Destroy GCP infrastructure
	cd init/terraform && terraform destroy -var="project_id=$(PROJECT_ID)" -auto-approve

infra-stop: ## Stop all K8s VMs to save costs
	@echo "Stopping instances with tag 'k8s-node'..."
	gcloud compute instances stop $$(gcloud compute instances list --filter="tags.items=k8s-node" --format="value(name,zone)" | awk '{print $$1 " --zone=" $$2}') --project $(PROJECT_ID)

infra-start: ## Start all K8s VMs
	@echo "Starting instances with tag 'k8s-node'..."
	gcloud compute instances start $$(gcloud compute instances list --filter="tags.items=k8s-node" --format="value(name,zone)" | awk '{print $$1 " --zone=" $$2}') --project $(PROJECT_ID)

#-- Kubernetes (Ansible) --

k8s-install: ## Install Kubernetes on VMs via Ansible
	sleep 20
	cd init/ansible && ansible-playbook playbooks/setup-k8s.yml

#-- Access & Connectivity --

kubeconfig: ## Fetch and merge Kubeconfigs (Contexts: paris, newyork)
	./scripts/fetch_kubeconfigs.sh

cilium-install: ## Install Cilium and connect clusters (Cluster Mesh)
	cd init/cilium && ./install.sh

certs-generate: ## Generate shared CA for Cilium Cluster Mesh
	./scripts/generate_clustermesh_ca.sh

dns-local: ## Update local /etc/hosts with CP Public IPs
	./scripts/update_local_hosts.sh

gateway-patch: ## Patch Gateway services with fixed NodePorts (30080, 30443)
	@echo "Patching Paris Gateway Service..."
	kubectl patch svc -n kube-system cilium-gateway-cilium-gateway --context paris --type='json' -p='[{"op": "replace", "path": "/spec/ports/0/nodePort", "value": 30080}, {"op": "replace", "path": "/spec/ports/1/nodePort", "value": 30443}]' || true
	@echo "Patching New York Gateway Service..."
	kubectl patch svc -n kube-system cilium-gateway-cilium-gateway --context newyork --type='json' -p='[{"op": "replace", "path": "/spec/ports/0/nodePort", "value": 30080}, {"op": "replace", "path": "/spec/ports/1/nodePort", "value": 30443}]' || true

gateway-api-install: ## Install Gateway API CRDs (v1.2.0)
	@echo "Installing Gateway API CRDs..."
	kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.0/standard-install.yaml --context paris
	kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.0/standard-install.yaml --context newyork

#-- Demo Application --

app-build: ## Build and Push Docker image (ttl.sh default)
	cd app && docker build -t $(IMAGE_NAME) . && docker push $(IMAGE_NAME)
	@echo "Image pushed: $(IMAGE_NAME)"

app-deploy-global: ## Deploy app with Global Service (Annotation)
	helm upgrade --install demo-app ./app/chart \
		--kube-context paris \
		--set image.repository=$(shell echo $(IMAGE_NAME) | cut -d: -f1) \
		--set image.tag=$(shell echo $(IMAGE_NAME) | cut -d: -f2) \
		--set clusterName=paris \
		-f ./app/chart/values-global-service.yaml
	helm upgrade --install demo-app ./app/chart \
		--kube-context newyork \
		--set image.repository=$(shell echo $(IMAGE_NAME) | cut -d: -f1) \
		--set image.tag=$(shell echo $(IMAGE_NAME) | cut -d: -f2) \
		--set clusterName=newyork \
		-f ./app/chart/values-global-service.yaml

app-deploy-mcs: ## Deploy app with MCS API (ServiceExport)
	helm upgrade --install demo-app ./app/chart \
		--kube-context paris \
		--set image.repository=$(shell echo $(IMAGE_NAME) | cut -d: -f1) \
		--set image.tag=$(shell echo $(IMAGE_NAME) | cut -d: -f2) \
		--set clusterName=paris \
		-f ./app/chart/values-mcs.yaml

	helm upgrade --install demo-app ./app/chart \
		--kube-context newyork \
		--set image.repository=$(shell echo $(IMAGE_NAME) | cut -d: -f1) \
		--set image.tag=$(shell echo $(IMAGE_NAME) | cut -d: -f2) \
		--set clusterName=newyork \
		-f ./app/chart/values-mcs.yaml

#-- All-in-One --

setup-all: infra-create k8s-install dns-local kubeconfig certs-generate gateway-api-install ## Run full setup (Infra -> K9s -> Cilium -> Gateway)
	@echo "Setup complete! You can now deploy the app with 'make app-deploy-global'"
