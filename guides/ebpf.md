# eBPF study guide

Covers what eBPF is, why Kubernetes networking moved to it, and how to read the eBPF state behind a networking decision. It expands the eBPF row of the Fundamentals table in [STUDY_PLAN.md](../STUDY_PLAN.md).

Study the key fundamentals, and make sure you can answer the questions at the end of the Study part, before you start the Labs part. Read [kubernetes-networking.md](kubernetes-networking.md) first, and [go.md](go.md) before the labs that load programs from Go.

## Study

### Key fundamentals

| # | Concept | What to understand |
| --- | --- | --- |
| 1 | What eBPF is | Small programs that run inside the kernel at defined hooks, checked for safety before they run, so kernel behaviour can change without a kernel module or a rebuild |
| 2 | The verifier | It proves a program terminates and never reads memory it shouldn't; it rejects unbounded loops, unchecked pointers, and packet access without a bounds check; accepted programs are compiled to native code |
| 3 | Networking hooks | XDP runs earliest, on ingress only, before the kernel builds a socket buffer; tc (and tcx) runs on ingress and egress with the full socket buffer; socket and cgroup hooks run when a process connects or sends |
| 4 | Tracing hooks | kprobes, tracepoints, and fentry attach to kernel functions and events, for observing instead of forwarding |
| 5 | Maps | Key-value stores shared between kernel programs and user space: hash, array, per-CPU variants, LRU, longest-prefix-match tries for CIDR lookups, and ring buffers for events |
| 6 | From source to a running program | Restricted C is compiled with clang to bytecode; BTF and CO-RE let one binary run on different kernels; a user-space loader creates the maps, loads the program through the verifier, and attaches it through a link; it stays loaded while something holds a reference or it is pinned |
| 7 | eBPF from Go | The `cilium/ebpf` library loads and attaches programs; `bpf2go` compiles the C and generates Go bindings |
| 8 | Why it replaces iptables | A hash lookup instead of a chain of rules checked in order; small map updates instead of reloading long rule lists; Service addresses translated once per connection at the socket instead of once per packet; flow visibility from the same place that enforces |
| 9 | How Cilium uses it | Programs on each pod's interface for routing and policy, socket-level hooks for Service load balancing, and maps for policy, connection tracking, NAT, and identities |
| 10 | Inspecting a running system | `bpftool` lists and dumps programs, maps, and links; `bpftrace` runs one-line tracing programs |
| 11 | Limits and risks | Loading needs elevated privileges; behaviour depends on the kernel version; programs have a small stack and a complexity cap; several tools can share a hook and interfere; the agent that loads them becomes critical |

### Reading

1. Rows 1 to 5: [What is eBPF?](https://ebpf.io/what-is-ebpf/), then the first chapters of *Learning eBPF* by Liz Rice, which [ebpf.io](https://ebpf.io/get-started) lists among its starting points.
2. Rows 6 and 7: the [ebpf-go getting started guide](https://ebpf-go.dev/guides/getting-started/), then one example from the [`cilium/ebpf`](https://github.com/cilium/ebpf) `examples/` directory, read line by line.
3. Rows 8 and 9: [cilium.md](cilium.md) and the Cilium component overview linked from the study plan.
4. Row 10: the `bpftool` and `bpftrace` man pages.

### Drills

Short checks before any lab. Most need only a Linux VM.

- [ ] `bpftool prog show` and `bpftool map show` on any Linux host; for one program, say its type and which maps it uses
- [ ] Run three bpftrace one-liners: count system calls by process, trace TCP connects, trace packet drops
- [ ] From an example program, point to the map definition, the bounds check, and the return code, and say what happens if each is removed
- [ ] Explain in two sentences why a hash lookup scales better than a long chain of iptables rules

### Pitfalls

- The verifier rejects packet access that has no bounds check, and a map lookup result that is used without a null check.
- Multi-byte header fields are in network byte order. Convert before comparing.
- A program detaches when the last reference to its link is closed, unless the link is pinned. A loader that exits takes the program with it.
- Loading your own program on an interface that Cilium manages can conflict with it. Use a separate interface for experiments.
- A program that works on one kernel can fail to load on another. Note the kernel version in every lab.

### Questions you should be able to answer

After studying this guide, you should be able to answer the questions below. Answer each out loud, without notes, in about two minutes. The right-hand column is a checklist of what a strong answer covers, not a script.

| # | Question | A strong answer covers |
| --- | --- | --- |
| 1 | What is eBPF, and why does it matter for Kubernetes? | Verified programs at kernel hooks; no kernel module; used for networking, observability, and runtime security; it is what lets a CNI replace kube-proxy and iptables and report every flow |
| 2 | How does the kernel make sure an eBPF program is safe? | The verifier checks every path: bounded loops, checked pointers and packet bounds, only the helpers allowed for that program type; then the program is compiled to native code; loading needs privileges |
| 3 | When would you attach at XDP and when at tc? | XDP for the earliest and cheapest drop or redirect on ingress, such as DDoS filtering and load balancing; tc when you need egress as well, or the socket buffer's metadata, as pod policy does |
| 4 | What is a map, and how do kernel and user space share one? | A kernel key-value store with a fixed type; programs use helpers, user space uses system calls through a library or `bpftool`; maps hold state between packets and carry configuration and events; per-CPU maps avoid locking |
| 5 | Why is an eBPF dataplane faster than iptables at scale? | Hash lookups instead of rules checked in order; incremental updates; per-connection Service translation at the socket; and the honest caveat that on a small cluster the difference is hard to measure |
| 6 | How does a program get from C source to running on an interface, and what keeps it there? | clang to bytecode; BTF and CO-RE for portability; a loader creates maps, loads through the verifier, and attaches through a link; it lives while a file descriptor is held or the link is pinned |
| 7 | What are the risks of running eBPF in production? | Kernel version dependencies, privileges, verifier limits, harder debugging, tools that share a hook, and a node agent that is now critical; mitigations are version pinning, staged rollouts, and knowing the inspection tools |

**Scenario to practise.** A pod's packets are being dropped and no iptables rule explains it. Describe how you would find the eBPF program that dropped them, and with which tools.

### Go further

Optional. Come back to these after the labs.

- Parsing Ethernet, IP, and TCP headers by hand in an XDP program
- Tail calls and how large datapaths are split into several programs
- [`pwru`](https://github.com/cilium/pwru) for tracing a packet through the kernel
- LSM hooks and runtime security tools built on eBPF
- Socket maps for redirecting traffic between sockets

## Labs

Do these once you can answer the questions above.

- [ ] [STUDY_PLAN.md](../STUDY_PLAN.md), "eBPF and Cilium core": bpftrace one-liners, the XDP packet counter in Go, and the datapath inspection task
- [ ] [BUILD_PLAN.md](../BUILD_PLAN.md) stage 5: read the eBPF state behind one agent request
- [ ] [BUILD_PLAN.md](../BUILD_PLAN.md) stage 6, extension: the eBPF flow counter

## Sources

- [What is eBPF?](https://ebpf.io/what-is-ebpf/)
- [ebpf.io: Get started](https://ebpf.io/get-started)
- [ebpf-go: Getting started](https://ebpf-go.dev/guides/getting-started/)
- [cilium/ebpf](https://github.com/cilium/ebpf)
- [pwru](https://github.com/cilium/pwru)
