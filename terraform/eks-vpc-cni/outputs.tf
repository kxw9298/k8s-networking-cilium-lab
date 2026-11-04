output "update_kubeconfig" {
  description = "Point kubectl at the cluster."
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name}"
}

output "explore" {
  description = "First things to look at."
  value       = <<-EOT
    kubectl -n kube-system get ds aws-node -o wide
    kubectl -n kube-system get ds aws-node -o jsonpath='{.spec.template.spec.containers[0].env}' | jq
    kubectl get nodes -o custom-columns=NAME:.metadata.name,MAX_PODS:.status.allocatable.pods
    kubectl get pods -A -o wide
  EOT
}
