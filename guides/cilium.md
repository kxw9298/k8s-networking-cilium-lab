# Cilium study guide

Covers Cilium's architecture, identity-based policy, the datapath, DNS-aware and L7 policy, and Hubble. It expands the Cilium architecture row of the Fundamentals table in [STUDY_PLAN.md](../STUDY_PLAN.md).

Study the key fundamentals, and make sure you can answer the questions at the end of the Study part, before you start the Labs part. Read [kubernetes-networking.md](kubernetes-networking.md) and [ebpf.md](ebpf.md) first.

## Study

### Key fundamentals

| # | Concept | What to understand |
| --- | --- | --- |
| 1 | Components | An agent on every node programs the datapath; an operator handles cluster-wide work; the CNI plugin wires up each pod; Envoy handles L7; Hubble exposes flows |
| 2 | Endpoints and identity | An endpoint is a pod's network presence; its security identity is a number derived from the pod's labels, shared by all pods with the same labels; there are reserved identities for the host, the world outside the cluster, and other fixed entities |
| 3 | Policy by identity | Rules name identities, not addresses, so a pod that restarts with a new IP keeps its policy; a map from IP to identity lets the datapath recognise the peer |
| 4 | Datapath | eBPF programs on each pod's interface route packets and enforce policy; connection tracking and NAT live in eBPF maps; pods are reached by encapsulation (VXLAN or Geneve) or by native routing |
| 5 | Service load balancing | Cilium can replace kube-proxy; a Service lookup is a map lookup, done at the socket for traffic from pods and at the interface for traffic from outside |
| 6 | Policy model | An endpoint allows everything until a policy selects it; then that direction is default-deny and only listed traffic passes; namespaced and cluster-wide policy kinds; deny rules |
| 7 | L3 and L4 rules | Selecting peers by labels, by entity (such as the world or the cluster), by CIDR, and by port and protocol |
| 8 | DNS-aware policy | `toFQDNs` allows destinations by name; a DNS rule sends the pod's lookups through Cilium's DNS proxy, which records the name-to-IP answers that the policy then uses |
| 9 | L7 policy | HTTP rules by method, path, and headers; matching traffic is redirected to Envoy, which allows each request or rejects it with a 403 |
| 10 | Hubble | Flow records with a verdict (forwarded, dropped, redirected) and a drop reason; the CLI, the relay that aggregates across nodes, and the service map |
| 11 | Encryption | WireGuard and IPsec encrypt traffic between nodes; that protects the wire but does not prove which workload is on the other end |
| 12 | Managed offerings | GKE Dataplane V2 and Azure CNI Powered by Cilium are built on Cilium and expose only part of it; on EKS you install Cilium yourself |

### Reading

1. Rows 1 to 5: the [Cilium component overview](https://docs.cilium.io/en/stable/overview/component-overview/), then [Kubernetes without kube-proxy](https://docs.cilium.io/en/stable/network/kubernetes/kubeproxy-free/).
2. Rows 6 to 9: the network policy section of the Cilium documentation, including its pages on DNS-based and L7 policy.
3. Row 10: the Hubble section of the Cilium documentation.
4. All of it, hands-on: the free "Getting Started with Cilium" lab from [Isovalent](https://isovalent.com/labs/).

### Drills

Short checks before any lab.

- [ ] Draw the components on one node and say which one acts when a pod starts, when a policy changes, and when an HTTP request is checked
- [ ] Write a policy from memory that allows one pod to reach one domain on port 443 and nothing else, including the DNS rule it needs
- [ ] For a pod with labels `app=agent` and `team=research`, say what changes when the `team` label is edited, and why
- [ ] Explain in two sentences why an FQDN rule keeps working when the destination's address changes

### Pitfalls

- An FQDN rule without a DNS rule never matches, because Cilium never sees the lookups.
- Adding the first policy that selects a pod switches that direction to default-deny. Everything not listed stops, including DNS.
- L7 rules apply to traffic Cilium can read. Traffic the pod has already encrypted is opaque to them.
- A policy that selects by label is only as good as control over who can set labels.
- Command names and flags change between releases. Record the Cilium version in every lab.

### Questions you should be able to answer

After studying this guide, you should be able to answer the questions below. Answer each out loud, without notes, in about two minutes. The right-hand column is a checklist of what a strong answer covers, not a script.

| # | Question | A strong answer covers |
| --- | --- | --- |
| 1 | Why choose Cilium over a CNI built on iptables, and what does it cost? | eBPF datapath, identity-based policy, DNS-aware and L7 policy, flow visibility with Hubble, kube-proxy replacement; the cost is kernel requirements, more to operate, a critical node agent, and gaps on managed offerings |
| 2 | How does identity-based policy work, and why is it better than rules on IP addresses? | Labels become a numeric identity shared by matching pods; a map from IP to identity tells the datapath who the peer is; each endpoint's policy map is keyed by identity and port; pod churn changes IPs but not rules |
| 3 | What happens to a pod's traffic when the first policy selects it? | That direction becomes default-deny; the other direction is untouched; DNS stops unless it is allowed; roll out by watching flows first, then enforcing |
| 4 | How does an FQDN policy work end to end, and where are its limits? | The DNS rule sends lookups through the DNS proxy; the proxy records name-to-IP answers; connections to those IPs are allowed; limits: only names resolved through the proxy count, an IP shared by many names is allowed for all of them, and it says nothing about the request inside the connection |
| 5 | Where is an L7 rule enforced, and what can it not see? | eBPF redirects matching traffic to Envoy on the node; Envoy allows the request or returns a 403; it cannot read traffic the application already encrypted, and it adds a proxy hop |
| 6 | How does Cilium deliver traffic to a Service without kube-proxy? | Service and backend data in eBPF maps; for pod traffic the address is translated at the socket when the connection is made, so there is no per-packet NAT; traffic from outside is handled at the node's interface |
| 7 | A request from a pod fails. How do you find out whether Cilium dropped it, and why? | Hubble flows for that pod filtered to dropped verdicts; read the drop reason, the direction, and both identities; check the endpoint's policy state in the agent; check DNS; only then look outside Cilium |
| 8 | How do managed Kubernetes services use Cilium, and what do you check before relying on a feature? | GKE Dataplane V2 and Azure CNI Powered by Cilium are Cilium underneath with a reduced feature set; check L7 policy, FQDN policy, Hubble, and which CRDs are accepted before designing around them |

**Scenario to practise.** A namespace of AI agent pods may reach one model API on the internet and one internal tool server, and nothing else. Design the egress policy, say how you would roll it out without an outage, and say how you would prove it works.

### Go further

Optional. Come back to these after the labs.

- Cluster Mesh for shared Services and identities across clusters
- Load-balancer address management and BGP
- Egress gateway, for a stable source address that an upstream firewall can allow
- Cilium as a Gateway API implementation
- Workload-level mutual authentication, which is changing between releases
- Routing modes and IPAM modes in depth

## Labs

Do these once you can answer the questions above.

- [ ] [STUDY_PLAN.md](../STUDY_PLAN.md), "eBPF and Cilium core": install Cilium, inspect the datapath, write the policies, and find a drop in Hubble
- [ ] [BUILD_PLAN.md](../BUILD_PLAN.md) stage 1: Cilium for agent workloads
- [ ] [BUILD_PLAN.md](../BUILD_PLAN.md) stage 5: explain the dataplane
- [ ] [STUDY_PLAN.md](../STUDY_PLAN.md), "Cilium advanced": Gateway API first, then the rest in any order

## Sources

- [Cilium component overview](https://docs.cilium.io/en/stable/overview/component-overview/)
- [Cilium: Kubernetes without kube-proxy](https://docs.cilium.io/en/stable/network/kubernetes/kubeproxy-free/)
- [Isovalent hands-on labs](https://isovalent.com/labs/)
