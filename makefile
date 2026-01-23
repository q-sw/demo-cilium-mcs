.PHONY: help infra-init infra-create infra-destroy k8s-install kubeconfig cilium-install setup-all setup-dns-local

# Variables
PROJECT_ID ?= $(shell gcloud config get-value project)
IMAGE_NAME ?= ttl.sh/demo-multi-cluster-$(shell git rev-parse --short HEAD):1h

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

#-- All-in-One --

setup-all: infra-create k8s-install dns-local kubeconfig certs-generate ## Run full setup (Infra -> K9s -> Cilium)
	@echo "Setup complete! You can now deploy the app with 'make app-deploy-global'"
