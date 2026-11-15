# Cilium study guide

Covers Cilium's architecture, identity-based policy, the datapath, L7 and DNS-aware policy, and Hubble. It expands the Cilium architecture row of the Fundamentals table in [STUDY_PLAN.md](../STUDY_PLAN.md).

Finish the Study part and pass the readiness check before you start the Labs part. Read [kubernetes-networking.md](kubernetes-networking.md) and [ebpf.md](ebpf.md) first.

## Study

### Concepts, in order

| # | Concept | What to understand |
| --- | --- | --- |
| 1 | Components | An agent on every node programs the datapath; an operator handles cluster-wide work; the CNI plugin wires up each pod; Envoy handles L7; Hubble exposes flows |
| 2 | Endpoints | Cilium's name for a pod's network presence; each has an ID, an identity, and its own policy state |
| 3 | Security identity | A number derived from a pod's labels; pods with the same labels share one; there are reserved identities for the host, the world outside the cluster, and other fixed entities |
| 4 | Policy by identity | Rules name identities, not addresses, so a pod that restarts with a new IP keeps its policy; a map from IP to identity lets the datapath recognise the peer |
| 5 | Datapath | eBPF programs on each pod's interface route packets and enforce policy; connection tracking and NAT are kept in eBPF maps |
| 6 | Service load balancing | Cilium can replace kube-proxy; a Service lookup is a map lookup, done at the socket for traffic from pods and at the interface for traffic from outside |
| 7 | Routing modes | Encapsulation (VXLAN or Geneve) or native routing; how pod IP ranges are allocated to nodes (IPAM modes) |
| 8 | Policy model | An endpoint allows everything until a policy selects it; then that direction is default-deny and only listed traffic passes; namespaced and cluster-wide policy kinds; deny rules |
| 9 | L3 and L4 rules | Selecting peers by labels, by entity (such as the world or the cluster), by CIDR, and by port and protocol |
| 10 | DNS-aware policy | `toFQDNs` allows destinations by name; a DNS rule sends the pod's lookups through Cilium's DNS proxy, which records the name-to-IP answers the policy then uses |
| 11 | L7 policy | HTTP rules by method, path, and headers; matching traffic is redirected to Envoy, which allows or rejects each request |
| 12 | Hubble | Flow records with a verdict (forwarded, dropped, redirected) and a drop reason; the CLI, the relay that aggregates across nodes, and the service map |
| 13 | Encryption and identity in transit | WireGuard and IPsec encrypt between nodes; workload-level mutual TLS adds proof of who the peer is |
| 14 | Beyond one cluster | Gateway API and ingress, load-balancer address management and BGP, Cluster Mesh for shared Services and identities |
| 15 | Tooling | `cilium` for install, status, and connectivity tests; `cilium-dbg` inside the agent for endpoints, identities, policy, and maps; `hubble` for flows |

### Reading

1. Concepts 1 to 7: the [Cilium component overview](https://docs.cilium.io/en/stable/overview/component-overview/), then [Kubernetes without kube-proxy](https://docs.cilium.io/en/stable/network/kubernetes/kubeproxy-free/).
2. Concepts 8 to 11: the network policy section of the Cilium documentation, including its pages on DNS-based and L7 policy.
3. Concept 12: the Hubble section of the Cilium documentation.
4. All of it, hands-on: the free "Getting Started with Cilium" lab from [Isovalent](https://isovalent.com/labs/).

### Drills

Short checks before any lab.

- [ ] Draw the components on one node and say which one acts when a pod starts, when a policy changes, and when an HTTP request is checked
- [ ] Write a policy from memory that allows one pod to reach one domain on port 443 and nothing else, including the DNS rule it needs
- [ ] For a pod with labels `app=agent` and `team=research`, say what changes when the `team` label is edited, and why
- [ ] List the verdicts Hubble can report and what each means
- [ ] Explain in two sentences why an FQDN rule keeps working when the destination's address changes

### Pitfalls to know before you build

- An FQDN rule without a DNS rule never matches, because Cilium never sees the lookups.
- Adding the first policy that selects a pod switches that direction to default-deny. Everything not listed stops, including DNS.
- L7 rules apply to traffic Cilium can read. Traffic the pod has already encrypted is opaque to them.
- A policy that selects by label is only as good as control over who can set labels.
- Managed offerings built on Cilium do not expose every feature. Check before you rely on one.
- Command names and flags change between releases. Record the Cilium version in every lab.

### Readiness check

Answer each out loud without notes.

1. What is a security identity, and how does the datapath know the identity of the peer on a packet?
2. What happens to a pod's traffic when the first policy selects it?
3. Walk through what Cilium does when a pod looks up a name that an FQDN rule allows.
4. Where is an L7 HTTP rule enforced, and what does the client see when it is denied?
5. How does Cilium deliver a request to a Service without kube-proxy?
6. A request is dropped. Which Hubble fields tell you why, and what would you check next?
7. What does node-to-node encryption protect against, and what does it not prove?

## Labs

Do these after the readiness check.

- [ ] [STUDY_PLAN.md](../STUDY_PLAN.md), "eBPF and Cilium core": install Cilium, inspect the datapath, write the policies, and find a drop in Hubble
- [ ] [BUILD_PLAN.md](../BUILD_PLAN.md) stage 1: Cilium for agent workloads
- [ ] [BUILD_PLAN.md](../BUILD_PLAN.md) stage 5: explain the dataplane
- [ ] [STUDY_PLAN.md](../STUDY_PLAN.md), "Cilium advanced": Gateway API first, then the rest in any order

## Sources

- [Cilium component overview](https://docs.cilium.io/en/stable/overview/component-overview/)
- [Cilium: Kubernetes without kube-proxy](https://docs.cilium.io/en/stable/network/kubernetes/kubeproxy-free/)
- [Isovalent hands-on labs](https://isovalent.com/labs/)
