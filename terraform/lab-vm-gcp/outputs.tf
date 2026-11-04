output "ssh_command" {
  description = "SSH into the VM through IAP (no public SSH port)."
  value       = "gcloud compute ssh ${var.name} --zone ${var.zone} --project ${var.project_id} --tunnel-through-iap"
}

output "vscode_ssh_config" {
  description = "Add to ~/.ssh/config for VS Code Remote-SSH. Run ssh_command once first so gcloud creates your key; replace YOUR_USER with your local username."
  value       = <<-EOT
    Host ${var.name}
      HostName ${var.name}
      User YOUR_USER
      IdentityFile ~/.ssh/google_compute_engine
      ProxyCommand gcloud compute start-iap-tunnel ${var.name} 22 --listen-on-stdin --zone ${var.zone} --project ${var.project_id}
  EOT
}

output "stop_and_start" {
  description = "How to stop and start the VM between sessions."
  value       = "terraform apply -var running=false   # stop (disk is kept)\nterraform apply -var running=true    # start"
}
