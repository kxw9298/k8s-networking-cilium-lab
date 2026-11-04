# Setup

## 1. Get an Ubuntu 24.04 VM

Pick one:

- **Cloud (recommended for machines with less than 16 GB RAM):** a GCP e2-standard-8 (8 vCPU, 32 GB), managed with Terraform in [`../terraform/lab-vm-gcp/`](../terraform/lab-vm-gcp/). SSH goes through IAP only, and you stop the VM between sessions with `terraform apply -var running=false`. See [`../terraform/README.md`](../terraform/README.md).
- **macOS on Apple Silicon:** OrbStack. See [macOS on Apple Silicon](#macos-on-apple-silicon) below.
- **Other local options:** Lima or UTM on macOS, VirtualBox or Hyper-V, WSL2 on Windows, or native Linux. Give the VM 4–6 vCPUs, 8–12 GB RAM, and 50 GB disk.

You need a Linux VM, not just Docker: the Linux networking and eBPF labs run directly on the VM's kernel. Docker Desktop's built-in Kubernetes is not used either, because its CNI and kube-proxy can't be replaced; the labs run kind instead.

## macOS on Apple Silicon

OrbStack runs a lightweight Ubuntu machine (and a Docker engine), so neither Docker Desktop nor VirtualBox is needed.

**On the Mac:**

| Software | Why | Install |
| --- | --- | --- |
| Homebrew | Package manager for the rest | [brew.sh](https://brew.sh) |
| OrbStack | Runs the Ubuntu machine | `brew install orbstack` |
| VS Code + Remote - SSH extension | Edit files in the Ubuntu machine or the cloud VM | [code.visualstudio.com](https://code.visualstudio.com) |
| git | Clone this repo | `xcode-select --install` |
| Terraform | Cloud lab VM and cloud CNI sessions (optional) | `brew install hashicorp/tap/terraform` |
| Google Cloud CLI | Authenticate Terraform and SSH to the cloud VM (optional) | [cloud.google.com/sdk](https://cloud.google.com/sdk/docs/install) |
| AWS CLI | EKS session only (optional) | `brew install awscli` |

**Create the Ubuntu machine and install the toolchain:**

```bash
orb create ubuntu:noble lab     # Ubuntu 24.04, arm64
orb -m lab                      # shell into it
git clone https://github.com/kxw9298/k8s-networking-cilium-lab.git
cd k8s-networking-cilium-lab && ./setup/install-tools.sh
```

For VS Code, connect with Remote - SSH to `lab@orb` (OrbStack's built-in SSH server).

**Notes:**

- Set a memory limit in OrbStack's settings that leaves enough for macOS. Around 4 GB covers weeks 1–2 (single kind cluster); the Cilium-heavy weeks need 8–12 GB, or the cloud VM.
- OrbStack uses its own Linux kernel, so `install-tools.sh` may warn that bpftool is unavailable. Once Cilium is running, use the copy in the Cilium agent instead: `kubectl -n kube-system exec ds/cilium -- bpftool prog show`.

## 2. Install the toolchain

Inside the VM, clone this repo, then:

```bash
./setup/install-tools.sh
```

It installs Docker, kubectl, kind, Helm, the Cilium and Hubble CLIs, bpftool, bpftrace, tcpdump, conntrack, and Go (amd64 or arm64), and raises the inotify limits needed to run several kind clusters. Log out and back in afterwards.

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
