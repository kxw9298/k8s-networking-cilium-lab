# Setup

## 1. Get an Ubuntu 24.04 VM

Pick one:

- **Cloud (recommended for laptops with 8 GB RAM):** a GCP e2-standard-8 (8 vCPU, 32 GB).
  ```bash
  gcloud config set project <your-project>
  ./setup/gcp-vm.sh create
  ./setup/gcp-vm.sh config-ssh   # then connect with VS Code Remote-SSH
  ./setup/gcp-vm.sh stop         # after every session
  ```
  Set a billing budget alert before you start.
- **Local:** OrbStack, Lima, or UTM on macOS (arm64 image on Apple Silicon), WSL2 on Windows, or native Linux. Give the VM 4–6 vCPUs, 8–12 GB RAM, and 50 GB disk.

## 2. Install the toolchain

Inside the VM, clone this repo, then:

```bash
./setup/install-tools.sh
```

It installs Docker, kubectl, kind, Helm, the Cilium and Hubble CLIs, bpftool, bpftrace, tcpdump, conntrack, and Go, and raises the inotify limits needed to run several kind clusters. Log out and back in afterwards.

## 3. Create the base cluster

```bash
kind create cluster --config setup/kind-cilium.yaml
cilium install --set kubeProxyReplacement=true \
  --set k8sServiceHost=kind-control-plane --set k8sServicePort=6443
cilium status --wait
cilium hubble enable --ui
cilium connectivity test
```

Nodes stay NotReady until Cilium is installed. Delete the cluster with `kind delete cluster` when you're done.
