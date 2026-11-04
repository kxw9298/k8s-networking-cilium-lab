#!/usr/bin/env bash
# Creates and manages the lab VM on Google Cloud.
# Usage: ./setup/gcp-vm.sh create|start|stop|ssh|config-ssh|delete
# Override with environment variables, e.g. ZONE=us-central1-a ./setup/gcp-vm.sh create
# Uses the project from `gcloud config get-value project`. Stop the VM after every session.
set -euo pipefail

NAME="${VM_NAME:-k8s-net-lab}"
ZONE="${ZONE:-us-east1-b}"
MACHINE="${MACHINE:-e2-standard-8}" # 8 vCPU, 32 GB
DISK_GB="${DISK_GB:-50}"

case "${1:-}" in
  create)
    gcloud compute instances create "$NAME" \
      --zone "$ZONE" \
      --machine-type "$MACHINE" \
      --image-family ubuntu-2404-lts-amd64 \
      --image-project ubuntu-os-cloud \
      --boot-disk-size "${DISK_GB}GB" \
      --boot-disk-type pd-balanced
    ;;
  start | stop | delete)
    gcloud compute instances "$1" "$NAME" --zone "$ZONE"
    ;;
  ssh)
    gcloud compute ssh "$NAME" --zone "$ZONE"
    ;;
  config-ssh)
    # Adds the VM to ~/.ssh/config so VS Code Remote-SSH can connect to it.
    gcloud compute config-ssh
    ;;
  *)
    echo "Usage: $0 create|start|stop|ssh|config-ssh|delete" >&2
    exit 1
    ;;
esac
