variable "region" {
  description = "AWS region for the short-lived EKS cluster."
  type        = string
  default     = "us-east-1"
}

variable "name" {
  description = "Cluster name, also used for the VPC."
  type        = string
  default     = "vpc-cni-lab"
}

variable "kubernetes_version" {
  description = "EKS Kubernetes version (for example \"1.34\"). Pick one in standard support: older versions bill extra for extended support."
  type        = string
}

variable "api_allowed_cidrs" {
  description = "CIDRs allowed to reach the public Kubernetes API endpoint. Set to your own IP as x.x.x.x/32."
  type        = list(string)
}

variable "instance_type" {
  description = "Worker node instance type. Its ENI and IP limits decide how many pods fit per node."
  type        = string
  default     = "t3.medium"
}

variable "node_count" {
  description = "Number of worker nodes."
  type        = number
  default     = 2
}

variable "spot" {
  description = "Use Spot capacity for the nodes."
  type        = bool
  default     = true
}

variable "enable_prefix_delegation" {
  description = "VPC CNI prefix delegation (/28 prefixes per ENI slot). Start with false to see the default per-IP limits, then flip to true and compare."
  type        = bool
  default     = false
}
