variable "project_id" {
  description = "GCP project to create the lab VM in. Use a personal project."
  type        = string
}

variable "region" {
  description = "Region for the lab network."
  type        = string
  default     = "us-east1"
}

variable "zone" {
  description = "Zone for the lab VM. Must be inside var.region."
  type        = string
  default     = "us-east1-b"
}

variable "name" {
  description = "Name used for the VM and its network resources."
  type        = string
  default     = "k8s-net-lab"
}

variable "machine_type" {
  description = "VM size. e2-standard-8 (8 vCPU, 32 GB) fits two kind clusters with Cilium."
  type        = string
  default     = "e2-standard-8"
}

variable "disk_size_gb" {
  description = "Boot disk size in GB."
  type        = number
  default     = 50
}

variable "spot" {
  description = "Use a Spot VM (much cheaper, but Google can stop it at any time; running clusters are lost)."
  type        = bool
  default     = false
}

variable "running" {
  description = "Set to false and apply to stop the VM between sessions; set back to true to start it."
  type        = bool
  default     = true
}

variable "ssh_source_ranges" {
  description = "Optional extra CIDRs allowed to SSH directly (for example your home IP as x.x.x.x/32). SSH through IAP works without this."
  type        = list(string)
  default     = []
}

variable "billing_account_id" {
  description = "Optional billing account ID (XXXXXX-XXXXXX-XXXXXX). When set, a monthly budget with email alerts is created for the project."
  type        = string
  default     = ""
}

variable "budget_usd" {
  description = "Monthly budget amount in USD for the alert. Only used when billing_account_id is set."
  type        = number
  default     = 30
}
