#!/usr/bin/env bash
# Installs the lab toolchain on Ubuntu 24.04 (amd64 or arm64).
# Safe to re-run. Review before running: it uses sudo and downloads official releases.
set -euo pipefail

ARCH="$(dpkg --print-architecture)" # amd64 or arm64
case "$ARCH" in
  amd64 | arm64) ;;
  *) echo "Unsupported architecture: $ARCH" >&2; exit 1 ;;
esac

latest_release() { # $1 = owner/repo on GitHub
  curl -fsSL "https://api.github.com/repos/$1/releases/latest" | jq -r .tag_name
}

echo "==> Base packages"
sudo apt-get update
sudo apt-get install -y \
  ca-certificates curl git jq make gcc clang llvm libbpf-dev \
  iproute2 iputils-ping bridge-utils iptables ipvsadm conntrack tcpdump dnsutils \
  bpftrace linux-tools-common

echo "==> bpftool (matches the running kernel)"
if ! sudo apt-get install -y "linux-tools-$(uname -r)"; then
  echo "WARNING: no linux-tools package for kernel $(uname -r) (common on OrbStack, WSL2 and other custom kernels)." >&2
  echo "         Once Cilium runs, use its copy: kubectl -n kube-system exec ds/cilium -- bpftool prog show" >&2
fi

echo "==> Docker"
if ! command -v docker >/dev/null 2>&1; then
  curl -fsSL https://get.docker.com | sudo sh
fi
sudo usermod -aG docker "$USER"

echo "==> kubectl"
K8S_VERSION="$(curl -fsSL https://dl.k8s.io/release/stable.txt)"
curl -fsSLo /tmp/kubectl "https://dl.k8s.io/release/${K8S_VERSION}/bin/linux/${ARCH}/kubectl"
sudo install -m 0755 /tmp/kubectl /usr/local/bin/kubectl

echo "==> kind"
KIND_VERSION="$(latest_release kubernetes-sigs/kind)"
curl -fsSLo /tmp/kind "https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-${ARCH}"
sudo install -m 0755 /tmp/kind /usr/local/bin/kind

echo "==> Helm"
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

echo "==> Cilium and Hubble CLIs"
install_cli() { # $1 = name, $2 = owner/repo
  local name="$1" version file
  version="$(latest_release "$2")"
  file="${name}-linux-${ARCH}.tar.gz"
  (
    cd /tmp
    curl -fsSL --remote-name-all \
      "https://github.com/$2/releases/download/${version}/${file}" \
      "https://github.com/$2/releases/download/${version}/${file}.sha256sum"
    sha256sum --check "${file}.sha256sum"
    sudo tar xzf "$file" -C /usr/local/bin
    rm -f "$file" "${file}.sha256sum"
  )
}
install_cli cilium cilium/cilium-cli
install_cli hubble cilium/hubble

echo "==> Go"
GO_VERSION="$(curl -fsSL 'https://go.dev/VERSION?m=text' | head -n1)"
curl -fsSLo /tmp/go.tgz "https://go.dev/dl/${GO_VERSION}.linux-${ARCH}.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf /tmp/go.tgz
rm -f /tmp/go.tgz
if ! grep -q '/usr/local/go/bin' "$HOME/.profile"; then
  echo 'export PATH="$PATH:/usr/local/go/bin:$HOME/go/bin"' >>"$HOME/.profile"
fi

echo "==> Kernel limits for running several kind clusters"
printf 'fs.inotify.max_user_watches = 524288\nfs.inotify.max_user_instances = 512\n' |
  sudo tee /etc/sysctl.d/99-kind.conf >/dev/null
sudo sysctl --system >/dev/null

echo
echo "Installed:"
echo "  kubectl $(kubectl version --client -o json | jq -r .clientVersion.gitVersion)"
echo "  $(kind version)"
echo "  helm $(helm version --short)"
echo "  $(cilium version --client 2>/dev/null | head -n1)"
echo "  $(hubble version 2>/dev/null)"
echo "  $(/usr/local/go/bin/go version)"
echo
echo "Next: log out and back in (Docker group, Go PATH), then:"
echo "  kind create cluster --config setup/kind-cilium.yaml"
echo
echo "containerlab (week 4 BGP lab) is not installed here; follow https://containerlab.dev/install/"
