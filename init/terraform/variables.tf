variable "project_id" {
  description = "The GCP Project ID"
  type        = string
  default     = "qsw-demo-multi-cluster"
}

variable "region_paris" {
  description = "Region for the first simulated DC (Paris)"
  type        = string
  default     = "europe-west9"
}

variable "region_newyork" {
  description = "Region for the second simulated DC (New York)"
  type        = string
  default     = "us-east1"
}

variable "cidr_paris" {
  description = "CIDR block for Paris VPC"
  type        = string
  default     = "10.10.0.0/16"
}

variable "cidr_newyork" {
  description = "CIDR block for New York VPC"
  type        = string
  default     = "10.20.0.0/16"
}

variable "machine_type" {
  description = "Machine type for K8s nodes"
  type        = string
  default     = "e2-standard-4"
}

variable "ssh_pub_key_path" {
  description = "Path to the SSH public key to inject into VMs"
  type        = string
  default     = "~/dev/00_sshconfig/id_ecdsa.pub"
}

variable "authorized_source_ranges" {
  description = "List of public IPs/CIDRs allowed to SSH into VMs"
  type        = list(string)
  default     = ["90.108.210.138/32", "92.184.97.33/32"]
}
