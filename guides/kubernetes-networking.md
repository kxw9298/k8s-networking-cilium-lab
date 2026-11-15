# Kubernetes networking study guide

Covers networking basics, Linux networking, the Kubernetes networking model, Services, DNS, NetworkPolicy, and CNI. It expands the first four rows of the Fundamentals table in [STUDY_PLAN.md](../STUDY_PLAN.md).

Finish the Study part and pass the readiness check before you start the Labs part.

## Study

### Concepts, in order

| # | Concept | What to understand |
| --- | --- | --- |
| 1 | IP addressing and subnets | CIDR notation, how to tell whether two addresses are on the same subnet, private ranges, why overlapping ranges break routing |
| 2 | Layer 2 and ARP | MAC addresses, how ARP maps an IP to a MAC on one segment, what a bridge or switch does with a frame |
| 3 | Routing | The routing table, longest-prefix match, default gateway, next hop, why the return path matters as much as the forward path |
| 4 | TCP and UDP | Ports, the three-way handshake, connection state, resets and timeouts, why UDP has no connection |
| 5 | NAT | Source NAT and masquerade, destination NAT, port mapping, what NAT does to the source address the server sees |
| 6 | DNS | Recursive resolution, record types (A, AAAA, CNAME, SRV), TTL and caching, search domains |
| 7 | MTU and encapsulation | Why a tunnel header shrinks usable packet size, fragmentation, path MTU discovery, the symptoms of an MTU mismatch |
| 8 | Network namespaces and veth | A namespace is a separate network stack; a veth pair is a cable between two namespaces; a bridge joins several |
| 9 | netfilter and iptables | Tables and chains (PREROUTING, INPUT, FORWARD, OUTPUT, POSTROUTING), where NAT and filtering happen, rule order |
| 10 | conntrack | The kernel remembers connections so replies are matched and un-NATed; what a full or stale table causes |
| 11 | The Kubernetes network model | Every pod has its own IP; pods reach each other without NAT; the node reaches its pods; the model says nothing about how |
| 12 | Pod networking | The pod sandbox owns the network namespace, containers in a pod share it, a veth links it to the node |
| 13 | CNI | A specification: the runtime calls a plugin with ADD or DEL and a JSON config; the plugin creates the interface, asks IPAM for an address, and sets routes; plugins can be chained |
| 14 | Cross-node traffic | Overlay (VXLAN, Geneve), native routing or BGP, and cloud VPC routing; the trade-off between simplicity, MTU, and visibility |
| 15 | Services | ClusterIP, NodePort, LoadBalancer, headless, and ExternalName; EndpointSlices track the backing pods; a Service IP is virtual and exists only as rules |
| 16 | kube-proxy | iptables, IPVS, and nftables modes; how a Service IP becomes a pod IP; session affinity; `externalTrafficPolicy` and source IP preservation |
| 17 | Cluster DNS | CoreDNS, the names a Service and a headless Service get, `resolv.conf` in a pod, `ndots` and why it multiplies lookups |
| 18 | Ingress and Gateway API | L7 entry points; Gateway API splits the roles of infrastructure owner and route owner |
| 19 | NetworkPolicy | Policies only allow; a pod becomes isolated in a direction once a policy selects it; selectors by pod, namespace, and IP block; no L7, no domain names; the CNI must enforce it |
| 20 | Cloud CNIs | VPC-native pod IPs, IP exhaustion, prefix delegation, how AWS VPC CNI, Azure CNI, and GKE differ |

### Reading

1. Concepts 1 to 7: a networking primer you trust. Stop when you can do subnet math and explain NAT without notes.
2. Concepts 8 to 10: `man ip`, `man ip-netns`, `man iptables`, and a netfilter packet-flow diagram.
3. Concepts 11, 15, 16: [Kubernetes: Services, load balancing, and networking](https://kubernetes.io/docs/concepts/services-networking/) and [Virtual IPs and service proxies](https://kubernetes.io/docs/reference/networking/virtual-ips/).
4. Concept 13: the [CNI specification](https://github.com/containernetworking/cni/blob/main/SPEC.md).
5. Concept 17: [DNS for Services and Pods](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/).
6. Concept 19: [Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/).
7. Concept 18: the [Gateway API](https://gateway-api.sigs.k8s.io) overview.

### Drills

Short checks to do on paper or in a single terminal, before any lab.

- [ ] Given `10.4.0.0/14`, split it into node ranges of `/24` and say how many nodes and pods per node that allows
- [ ] On paper, list the netfilter chains a packet crosses for three cases: into a local process, forwarded through the host, and sent by a local process
- [ ] Write out the DNS names a pod in namespace `agents` would try, in order, when it looks up `api.example.com` with `ndots:5`
- [ ] For a ClusterIP Service with three pods, write the sequence of address rewrites for one request and its reply
- [ ] Write a NetworkPolicy from memory that denies all egress from a namespace except DNS

### Pitfalls to know before you build

- A reply that takes a different path from the request is dropped by stateful devices. Check both directions.
- `ndots:5` makes external lookups try the cluster search domains first, so one name becomes several queries.
- A NetworkPolicy does nothing if the CNI does not enforce it, and the API server will still accept it.
- Allowing egress to a pod does not allow DNS. DNS needs its own rule.
- With `externalTrafficPolicy: Cluster` the backend sees a node address, not the client address.
- MTU problems look like "small requests work, large ones hang".

### Readiness check

Answer each out loud without notes. If you can't, go back to the concept.

1. Two pods on different nodes talk over an overlay. What does the packet look like on the wire, and what is the MTU cost?
2. What does a CNI plugin do on ADD, and who calls it?
3. How does a ClusterIP become a pod IP in iptables mode, and where is the reply rewritten?
4. Why does a pod sometimes make five DNS queries for one external name?
5. A NetworkPolicy selects a pod for egress and lists one allowed destination. What else is now blocked?
6. Why can't a standard NetworkPolicy allow a domain name?
7. In what order would you check DNS, Service, endpoints, pod, node, and policy when a Service is unreachable, and with which commands?

## Labs

Do these after the readiness check. They are defined in [STUDY_PLAN.md](../STUDY_PLAN.md).

- [ ] The "Linux and Kubernetes networking" section: hand-built pods, Service tracing, IPVS, CoreDNS, and Calico policy
- [ ] The "CNI internals" section: read a node's CNI config, write a plugin in bash and then in Go, and work through an MTU problem

## Sources

- [Kubernetes: Services, load balancing, and networking](https://kubernetes.io/docs/concepts/services-networking/)
- [Kubernetes: Virtual IPs and service proxies](https://kubernetes.io/docs/reference/networking/virtual-ips/)
- [Kubernetes: DNS for Services and Pods](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/)
- [Kubernetes: Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
- [CNI specification](https://github.com/containernetworking/cni/blob/main/SPEC.md)
- [Gateway API](https://gateway-api.sigs.k8s.io)
