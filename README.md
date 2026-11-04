# Kubernetes Networking, CNI & Cilium Lab

Hands-on labs for Kubernetes networking, CNI internals, eBPF, and Cilium, built over four weeks on kind clusters.

- **The plan:** [STUDY_PLAN.md](STUDY_PLAN.md) has the week-by-week tasks, use cases, and self-check questions.
- **Environment:** [setup/](setup/) creates the Ubuntu lab VM, installs the toolchain, and defines the base kind cluster.
- **Labs:** [labs/](labs/) holds one folder per lab with its scripts, manifests, and findings.

## Quick start

```bash
# On an Ubuntu 24.04 VM (local or cloud)
./setup/install-tools.sh            # log out and back in afterwards for Docker group access
kind create cluster --config setup/kind-cilium.yaml
cilium install --set kubeProxyReplacement=true \
  --set k8sServiceHost=kind-control-plane --set k8sServicePort=6443
cilium status --wait
cilium connectivity test
```

## Progress

| Week | Focus | Status |
| --- | --- | --- |
| 1 | Linux and Kubernetes networking | Not started |
| 2 | CNI internals and a Go CNI plugin | Not started |
| 3 | eBPF and Cilium core | Not started |
| 4 | Cluster Mesh, encryption, BGP, cloud CNIs | Not started |
