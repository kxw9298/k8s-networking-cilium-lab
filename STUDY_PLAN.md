# Kubernetes Networking, CNI & Cilium Study Plan

A four-week, hands-on plan covering Kubernetes networking, CNI internals, eBPF, and Cilium. About 90% of it runs on a single Ubuntu VM with kind clusters; the cloud is needed only for one or two short sessions comparing managed CNIs (GKE Dataplane V2, AWS VPC CNI). Plan on 10–12 hours a week. The result is this repo of working labs, nine documented use cases, and readiness for the Cilium Certified Associate (CCA) exam.

## Laptop or cloud

Everything except the managed cloud CNIs runs locally. Cilium needs a Linux kernel 5.10 or newer on AMD64 or ARM64, so Intel and Apple Silicon machines both work inside a Linux VM ([Cilium system requirements](https://docs.cilium.io/en/latest/operations/system_requirements/)).

| Topic | Local VM | Cloud | Notes |
| --- | --- | --- | --- |
| Linux networking (namespaces, veth, bridges, iptables) | Yes | Not needed | Plain Linux in the VM |
| Services, kube-proxy, CoreDNS, NetworkPolicy | Yes (kind) | Not needed | |
| Writing a CNI plugin in Go | Yes (kind) | Not needed | |
| eBPF tools (bpftool, bpftrace, cilium/ebpf in Go) | Yes, in the Linux VM | Not needed | Needs a real Linux kernel, not macOS or Windows directly |
| Cilium: kube-proxy replacement, L3–L7 policy, Hubble, WireGuard, Gateway API | Yes (kind) | Not needed | |
| Cluster Mesh (multi-cluster) | Yes (two kind clusters) | Not needed | Needs about 8 GB RAM free in the VM |
| BGP | Yes (containerlab + FRR) | Not needed | |
| Managed CNIs: GKE Dataplane V2, AWS VPC CNI, Azure CNI | No | A few hours | Only exist in the cloud |

**Machine sizing:** 16 GB RAM minimum (32 GB comfortable), 4+ cores (8 better), and 50 GB free SSD. Intel, AMD, and Apple Silicon all work. Use a personal machine rather than a managed work laptop.

**If your laptop has 8 GB RAM:** that's too little for the full plan. Run the lab on a cloud Ubuntu 24.04 VM instead, such as a GCP e2-standard-8 (8 vCPU, 32 GB), at about $0.27 an hour on demand ([Vantage](https://instances.vantage.sh/gcp/e2-standard-8)). [`setup/gcp-vm.sh`](setup/gcp-vm.sh) creates, starts, and stops it. Connect with VS Code Remote-SSH, stop the VM after each session, and set a budget alert; four weeks should cost roughly $15–25. kind runs its nodes as containers, so the VM needs no nested virtualization.

**Cloud cost for managed-CNI sessions:** create each cluster, test, and delete it the same day; it should cost a few dollars. Use a personal cloud account.

**GKE note:** [Dataplane V2 is Google-managed Cilium](https://docs.cloud.google.com/kubernetes-engine/docs/concepts/dataplane-v2), run as the `anetd` DaemonSet, and GKE does not allow custom eBPF programs on those nodes. Learn on upstream Cilium in the lab, then use a GKE session to see how Google packages it.

## Lab setup

Run everything inside one Ubuntu 24.04 VM so the lab is the same on any machine. Give it 4–6 vCPUs, 8–12 GB RAM, and 50 GB disk (or use the cloud VM above).

| Laptop | How to get the Ubuntu VM |
| --- | --- |
| macOS (Intel or Apple Silicon) | OrbStack, Lima, or UTM; use the arm64 image on Apple Silicon |
| Windows | WSL2 with Ubuntu; if bpftrace misbehaves, use a Hyper-V or VirtualBox VM instead |
| Linux | Run natively, no VM needed |

Then follow [`setup/README.md`](setup/README.md): [`setup/install-tools.sh`](setup/install-tools.sh) installs Docker, kind, kubectl, Helm, the Cilium and Hubble CLIs, bpftool, bpftrace, tcpdump, conntrack, and Go.

**Base cluster:** three nodes, no default CNI, no kube-proxy, so Cilium does everything ([`setup/kind-cilium.yaml`](setup/kind-cilium.yaml)):

```bash
kind create cluster --config setup/kind-cilium.yaml
cilium install --set kubeProxyReplacement=true \
  --set k8sServiceHost=kind-control-plane --set k8sServicePort=6443
cilium status --wait
cilium hubble enable --ui
cilium connectivity test
```

Nodes stay NotReady until Cilium is installed; that's expected. kube-proxy replacement needs cgroup v2, which Ubuntu 24.04 uses by default ([Cilium kind guide](https://docs.cilium.io/en/stable/installation/kind/)).

## Four-week plan

Each week is about 10–12 hours: roughly 4 hours reading and 6–8 hours in the lab. Commit each lab's scripts and notes under [`labs/`](labs/) as you go.

### Week 1: Linux and Kubernetes networking

Goal: trace any packet path in a cluster.

- [ ] Build two "pods" by hand: network namespaces, a veth pair, a Linux bridge, routes, and NAT; ping between them and out to the internet
- [ ] kind cluster with the default CNI and kube-proxy in iptables mode: deploy two pods, a ClusterIP and a NodePort Service; trace them with `iptables-save` and `conntrack -L`
- [ ] Switch kube-proxy to IPVS mode and compare the rules
- [ ] CoreDNS: resolve a Service from a pod, read its `resolv.conf`, understand `ndots`
- [ ] Second kind cluster with Calico: apply default-deny plus allow rules, then find the iptables chains Calico writes
- [ ] Checkpoint: draw pod → Service → pod on one node and across nodes, from memory

### Week 2: CNI internals (and Go practice)

Goal: explain exactly what happens when a pod gets its network.

- [ ] Read the CNI spec: ADD, DEL, CHECK, VERSION; config in `/etc/cni/net.d`; plugins in `/opt/cni/bin`; IPAM
- [ ] `docker exec` into a kind node, read its CNI config, and watch what runs when a pod starts
- [ ] Write a minimal CNI plugin in bash, then rewrite it in Go with the `containernetworking/cni` libraries: veth pair, host-local IPAM, and a default route
- [ ] Run your plugin on a kind cluster with the default CNI disabled; add node-to-node routes so pods talk across nodes
- [ ] Compare overlay (VXLAN, Geneve) with native routing, and work through one MTU problem
- [ ] Read how AWS VPC CNI, Azure CNI, and GKE VPC-native assign pod IPs; note IP exhaustion and prefix delegation
- [ ] Checkpoint: explain kubelet → container runtime → CNI plugin for one pod start

### Week 3: eBPF and Cilium core

Goal: explain how Cilium replaces iptables, and enforce policy by identity.

- [ ] eBPF basics on [ebpf.io](https://ebpf.io): program types (XDP, tc, kprobe, tracepoint), maps, the verifier, CO-RE
- [ ] bpftrace one-liners: trace TCP connects and packet drops
- [ ] Small Go program with `cilium/ebpf`: an XDP packet counter
- [ ] Install Cilium on the base cluster with kube-proxy replacement; pass `cilium connectivity test`
- [ ] Inspect the datapath: `cilium-dbg status`, `cilium-dbg service list`, `bpftool prog show`, the service BPF maps
- [ ] Policies: default-deny, L3/L4, L7 HTTP by method and path, DNS-based egress with `toFQDNs`
- [ ] Hubble: watch flows, find a dropped packet, and read its drop reason
- [ ] Isovalent's free browser labs: Getting Started with Cilium, and Getting Started with eBPF
- [ ] Checkpoint: explain identity-based policy versus IP-based policy, and socket-level load balancing

### Week 4: Cilium advanced, multi-cluster, cloud comparison

Goal: design and defend a multi-region Cilium setup.

- [ ] Cluster Mesh across two kind clusters: a global Service, then failover when one cluster's backends go down
- [ ] WireGuard transparent encryption; confirm with `tcpdump` that pod traffic is encrypted between nodes
- [ ] Gateway API with Cilium for ingress
- [ ] BGP: a containerlab FRR router peering with Cilium to advertise LoadBalancer IPs
- [ ] Cloud session (optional): a GKE Dataplane V2 cluster to inspect `anetd`, or EKS to see VPC CNI IP allocation; delete it the same day
- [ ] Finish this repo's README with a diagram per lab
- [ ] Optional: CCA practice tests, then book the exam
- [ ] Checkpoint: whiteboard a two-region design with Cluster Mesh and explain what fails over and what breaks

## Use cases

Each lab is framed as a real platform problem rather than a tutorial to follow.

| Use case | What you build | Skill area | What it demonstrates |
| --- | --- | --- | --- |
| "My Service isn't reachable" | Packet traces with iptables, then with Cilium eBPF | Kubernetes networking, service discovery | Debugging a broken Service layer by layer |
| Isolating teams on a shared cluster | Default-deny, L7, and FQDN egress policies per team namespace | Multi-tenant isolation, policy-as-code | Hardening shared-services clusters |
| Root-causing a network incident | Hubble flows, drop reasons, service map | Incident RCA, observability | Finding a policy drop in minutes instead of hours |
| Replacing kube-proxy at scale | Compare iptables rule counts with 1,000 Services against Cilium's BPF maps | eBPF, Cilium | Why eBPF beats iptables as Service count grows |
| Multi-region failover | Cluster Mesh, global Services, failover test | Multi-cluster, multi-region architecture | Designing for the loss of a region |
| Zero Trust in transit | WireGuard encryption plus identity-based policy | Security architecture, Zero Trust | Meeting encryption-in-transit audit requirements |
| On-prem LoadBalancer | BGP peering with containerlab | Hybrid cloud | Exposing Services on-prem without a cloud load balancer |
| Picking a CNI | Comparison of cloud CNIs, Calico, and Cilium from the labs | Platform strategy, CNI implementations | Choosing a CNI for a given platform, with reasons |
| How a pod gets its network | Minimal CNI plugin in Go | CNI internals, Go | Walking through ADD/DEL in your own code |

## Self-check questions

By the end of week 4, answer each of these out loud without notes.

1. From `kubectl apply` of a Deployment to a running pod, what does each component do, and where does the CNI plugin run?
2. How does a ClusterIP Service work with kube-proxy in iptables mode, in IPVS mode, and with Cilium's eBPF replacement?
3. What does a CNI plugin do on ADD and DEL, and how does IPAM fit in?
4. Overlay versus native routing: when would you choose each, and what goes wrong with MTU?
5. How do AWS VPC CNI, Azure CNI, and GKE Dataplane V2 differ, and what is IP exhaustion on EKS?
6. How does Cilium enforce policy by identity rather than IP, and how does L7 policy work?
7. A pod can't reach an external API after a policy change. Walk through your debugging with Hubble.
8. How does Cluster Mesh share Services across clusters, and what happens when one cluster fails?
9. How would you encrypt pod-to-pod traffic, and how would you prove it to an auditor?
10. Which CNI would you pick for a multi-cloud platform on GKE, EKS, and AKS, and why?

## Sources

- [Cilium system requirements](https://docs.cilium.io/en/latest/operations/system_requirements/)
- [Cilium installation using kind](https://docs.cilium.io/en/stable/installation/kind/)
- [Cilium: Kubernetes without kube-proxy](https://docs.cilium.io/en/stable/network/kubernetes/kubeproxy-free/)
- [GKE Dataplane V2 overview](https://docs.cloud.google.com/kubernetes-engine/docs/concepts/dataplane-v2)
- [Cilium Certified Associate (CCA), CNCF](https://www.cncf.io/training/certification/cca/)
- [Isovalent hands-on labs](https://isovalent.com/labs/)
- [ebpf.io](https://ebpf.io)
