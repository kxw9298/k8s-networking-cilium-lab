output "get_credentials" {
  description = "Point kubectl at the cluster."
  value       = "gcloud container clusters get-credentials ${google_container_cluster.dpv2.name} --zone ${var.zone} --project ${var.project_id}"
}

output "explore" {
  description = "First things to look at."
  value       = <<-EOT
    kubectl -n kube-system get ds anetd -o wide
    kubectl -n kube-system exec ds/anetd -- cilium status
    kubectl -n kube-system exec ds/anetd -- cilium service list
    kubectl get networkpolicies -A
  EOT
}
