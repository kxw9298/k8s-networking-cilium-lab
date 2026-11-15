# Kubernetes networking study guide

Covers the networking a Kubernetes platform engineer is expected to explain: the Linux building blocks, the pod network, Services, DNS, NetworkPolicy, and CNI. It expands the first four rows of the Fundamentals table in [STUDY_PLAN.md](../STUDY_PLAN.md).

Study the key fundamentals, and make sure you can answer the questions at the end of the Study part, before you start the Labs part.

## Study

### Key fundamentals

| # | Concept | What to understand |
| --- | --- | --- |
| 1 | IP, subnets, and routing | CIDR notation, whether two addresses share a subnet, longest-prefix match, the default gateway, and why the return path matters as much as the forward path |
| 2 | TCP, UDP, and NAT | Ports, the three-way handshake, connection state; source NAT (masquerade) and destination NAT, and what each does to the address the server sees |
| 3 | Linux building blocks | A network namespace is a separate network stack; a veth pair is a cable between two namespaces; a bridge joins several; netfilter chains are where filtering and NAT happen; conntrack remembers connections so that replies are matched and un-NATed |
| 4 | The Kubernetes network model | Every pod has its own IP; pods reach each other without NAT; a node reaches its pods; the model says what must hold, not how |
| 5 | Pod networking and CNI | The pod sandbox owns the network namespace and the containers share it; the container runtime calls a CNI plugin with ADD or DEL and a JSON config; the plugin creates the interface, gets an address from IPAM, and sets routes |
| 6 | Cross-node and outbound traffic | Overlay (VXLAN, Geneve), native routing or BGP, and cloud VPC routing; a tunnel header shrinks the usable packet size, so the MTU has to allow for it; traffic that leaves the cluster is usually source-NATed to the node's address, which is what an external firewall sees |
| 7 | Services | ClusterIP, NodePort, LoadBalancer, and headless; a Service IP is virtual and exists only as rules; EndpointSlices list the pods behind it, and only pods that pass their readiness probe receive traffic |
| 8 | kube-proxy | It watches Services and EndpointSlices and programs each node (iptables, IPVS, or nftables mode); a Service IP is rewritten to a pod IP and conntrack rewrites the reply; `externalTrafficPolicy` decides whether the backend sees the client's address |
| 9 | Cluster DNS | CoreDNS answers for `service.namespace.svc.cluster.local`; a headless Service returns pod IPs; a pod's `resolv.conf` has search domains and `ndots:5`, which turns one external name into several lookups |
| 10 | Ingress and Gateway API | L7 entry points into the cluster; the Ingress API is frozen and new features go to Gateway API, which separates the infrastructure owner (Gateway) from the application owner (HTTPRoute) |
| 11 | NetworkPolicy | Policies only allow; a pod becomes isolated in a direction once a policy selects it; peers are chosen by pod labels, namespace labels, or IP block; no L7 rules, no domain names, no logging; the CNI must enforce it |
| 12 | Cloud CNIs | Pods get addresses from the VPC; what that means for IP exhaustion, prefix delegation, and firewalls; how AWS VPC CNI, Azure CNI, and GKE differ |

### Reading

1. Rows 1 to 3: a networking primer you trust, `man ip-netns`, and a netfilter packet-flow diagram. Stop when you can do subnet math and explain NAT without notes.
2. Rows 4, 7, and 8: [Kubernetes: Services, load balancing, and networking](https://kubernetes.io/docs/concepts/services-networking/) and [Virtual IPs and service proxies](https://kubernetes.io/docs/reference/networking/virtual-ips/).
3. Row 5: the [CNI specification](https://github.com/containernetworking/cni/blob/main/SPEC.md).
4. Row 9: [DNS for Services and Pods](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/).
5. Rows 10 and 11: [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/), the [Gateway API](https://gateway-api.sigs.k8s.io) overview, and [Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/).

### Drills

Short checks to do on paper or in a single terminal, before any lab.

- [ ] Given `10.4.0.0/14`, split it into node ranges of `/24` and say how many nodes that allows
- [ ] Write out the DNS names a pod in namespace `agents` tries, in order, when it looks up `api.example.com` with `ndots:5`
- [ ] For a ClusterIP Service with three pods, write the sequence of address rewrites for one request and its reply
- [ ] Write a NetworkPolicy from memory that denies all egress from a namespace except DNS

### Pitfalls

- A reply that takes a different path from the request is dropped by stateful devices. Check both directions.
- A NetworkPolicy does nothing if the CNI does not enforce it, and the API server still accepts it.
- Allowing egress to a pod does not allow DNS. DNS needs its own rule.
- With `externalTrafficPolicy: Cluster` the backend sees a node address, not the client address.
- MTU problems look like "small requests work, large ones hang".

### Questions you should be able to answer

After studying this guide, you should be able to answer the questions below. Answer each out loud, without notes, in about two minutes. The right-hand column is a checklist of what a strong answer covers, not a script.

| # | Question | A strong answer covers |
| --- | --- | --- |
| 1 | What happens on the network when a pod is created? | The kubelet asks the runtime for a sandbox with its own network namespace; the runtime calls the CNI plugin with ADD; the plugin creates a veth, gets an IP from IPAM, and sets routes; the containers join that namespace; once the pod passes its readiness probe, its address is marked ready in EndpointSlices and Services start sending to it |
| 2 | Trace a request from pod A to a ClusterIP Service backed by pod B on another node, and the reply. | DNS lookup for the Service name; the packet leaves for the Service IP; on the source node the Service IP is rewritten to a pod IP and conntrack records it; the packet is routed or encapsulated to the other node and delivered over pod B's veth; the reply is rewritten back by conntrack |
| 3 | Compare ClusterIP, NodePort, LoadBalancer, and headless. When does a backend lose the client's IP? | Each of the first three builds on the one before; headless has no virtual IP and DNS returns pod IPs; with `externalTrafficPolicy: Cluster` a node may forward to another node and source-NAT the packet; `Local` keeps the client address but only nodes with a local pod take traffic |
| 4 | What does kube-proxy do, and why do large clusters move away from iptables mode? | It turns Services and EndpointSlices into node rules; in iptables mode Service rules are checked one after another, so the cost of a new connection and the time to apply changes grow with the number of Services; IPVS, nftables, and eBPF dataplanes use hash or map lookups instead |
| 5 | How does a pod resolve a Service name, and why can one external name cost several queries? | `resolv.conf` points at the cluster DNS Service and lists search domains; with `ndots:5` a name with fewer than five dots is tried against each search domain first; fixes are a trailing dot, a lower `ndots`, or a node-local DNS cache |
| 6 | Overlay or native routing: what is the trade-off? | An overlay works on any network and hides pod IPs from it, at the cost of header overhead, a lower MTU, and less visibility; native routing has no encapsulation and firewalls see pod IPs, but the network must carry routes for the pod ranges (BGP or cloud routes) |
| 7 | What can NetworkPolicy do, and what can it not? | Allow-only and additive; default deny by selecting pods with no allowed peers; applies per direction; no L7, no domain names, no explicit deny, no cluster-wide scope, no logging; needs an enforcing CNI; DNS egress must be allowed explicitly |
| 8 | A Service is unreachable from a pod. How do you debug it? | A fixed order: does the name resolve; does the Service have endpoints (selector matches, pods ready); do port and `targetPort` match; does the pod IP answer directly; is a policy dropping it; is it the node, routing, or MTU. Name the command for each step |

**Scenario to practise.** Requests to a Service work when they are small and hang when they are large, and only between pods on different nodes. Explain the likely cause and how you would prove it.

### Go further

Optional. Come back to these after the labs.

- IPVS and nftables internals, and reading a full iptables rule set by hand
- BGP for pod and Service routes
- IPv6 and dual-stack clusters
- Cluster-scoped admin network policy
- Multi-cluster Services

## Labs

Do these once you can answer the questions above. They are defined in [STUDY_PLAN.md](../STUDY_PLAN.md).

- [ ] The "Linux and Kubernetes networking" section: hand-built pods, Service tracing, IPVS, CoreDNS, and Calico policy
- [ ] The "CNI internals" section: read a node's CNI config, write a plugin in bash and then in Go, and work through an MTU problem

## Sources

- [Kubernetes: Services, load balancing, and networking](https://kubernetes.io/docs/concepts/services-networking/)
- [Kubernetes: Virtual IPs and service proxies](https://kubernetes.io/docs/reference/networking/virtual-ips/)
- [Kubernetes: DNS for Services and Pods](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/)
- [Kubernetes: Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)
- [Kubernetes: Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
- [CNI specification](https://github.com/containernetworking/cni/blob/main/SPEC.md)
- [Gateway API](https://gateway-api.sigs.k8s.io)
