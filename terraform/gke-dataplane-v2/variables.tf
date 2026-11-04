variable "project_id" {
  description = "GCP project for the short-lived GKE cluster. Use a personal project."
  type        = string
}

variable "region" {
  description = "Region for the network."
  type        = string
  default     = "us-east1"
}

variable "zone" {
  description = "Zone for the zonal cluster. Must be inside var.region."
  type        = string
  default     = "us-east1-b"
}

variable "name" {
  description = "Cluster name, also used for its network resources."
  type        = string
  default     = "dpv2-lab"
}

variable "node_count" {
  description = "Number of nodes. Two is enough to see cross-node traffic."
  type        = number
  default     = 2
}

variable "machine_type" {
  description = "Node machine type."
  type        = string
  default     = "e2-standard-2"
}

variable "spot" {
  description = "Use Spot nodes to cut cost. Fine for a same-day lab."
  type        = bool
  default     = true
}
