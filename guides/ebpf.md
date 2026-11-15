# eBPF study guide

Covers what eBPF is, how programs are written, verified, loaded, and attached, and how to read the eBPF state behind a networking decision. It expands the eBPF row of the Fundamentals table in [STUDY_PLAN.md](../STUDY_PLAN.md).

Finish the Study part and pass the readiness check before you start the Labs part. Read [kubernetes-networking.md](kubernetes-networking.md) first, and [go.md](go.md) before the labs that load programs from Go.

## Study

### Concepts, in order

| # | Concept | What to understand |
| --- | --- | --- |
| 1 | What eBPF is | Small programs that run inside the kernel at defined hooks, checked for safety before they run, without writing a kernel module |
| 2 | The verifier | It proves a program terminates and never reads memory it shouldn't; it rejects unbounded loops, unchecked pointers, and packet access without a bounds check |
| 3 | Networking hooks | XDP runs earliest, on ingress, before the kernel builds a socket buffer; tc (and tcx) runs on ingress and egress with the full socket buffer; socket and cgroup hooks run when a process connects or sends |
| 4 | Tracing hooks | kprobes, tracepoints, and fentry attach to kernel functions and events, for observing instead of forwarding |
| 5 | Return codes | Each hook has its own verdicts, such as pass, drop, or redirect for XDP |
| 6 | Maps | Key-value stores shared between kernel programs and user space: hash, array, per-CPU variants, LRU, longest-prefix-match tries for CIDR lookups, and ring buffers for events |
| 7 | Helpers | Functions the kernel exposes to programs, such as map lookup, redirect, and reading the time; which ones are available depends on the program type and kernel version |
| 8 | The toolchain | Programs are written in restricted C and compiled with clang to eBPF bytecode; BTF and CO-RE let one binary run on different kernels |
| 9 | Loading and attaching | A user-space loader loads the program and maps, then attaches the program to a hook through a link; programs and maps live as long as something holds a reference or they are pinned |
| 10 | eBPF from Go | The `cilium/ebpf` library loads and attaches programs; `bpf2go` compiles the C and generates Go bindings for the programs and maps |
| 11 | Packet parsing | Walking Ethernet, IP, and TCP or UDP headers by hand, checking bounds at every step, and converting network byte order |
| 12 | Inspecting a running system | `bpftool` lists and dumps programs, maps, and links; `bpftrace` runs one-line tracing programs; trace output for debugging |
| 13 | How Cilium uses eBPF | Programs on each pod's interface for routing and policy, socket-level hooks for Service load balancing, and maps for policy, connection tracking, NAT, and identities |
| 14 | Limits | Required privileges, kernel version differences, stack and complexity limits, and how programs from different tools share a hook |

### Reading

1. Concepts 1 to 7: [What is eBPF?](https://ebpf.io/what-is-ebpf/), then the first chapters of *Learning eBPF* by Liz Rice, which [ebpf.io](https://ebpf.io/get-started) lists among its starting points.
2. Concepts 8 to 10: the [ebpf-go getting started guide](https://ebpf-go.dev/guides/getting-started/), then one example from the [`cilium/ebpf`](https://github.com/cilium/ebpf) `examples/` directory, read line by line.
3. Concepts 11 and 12: the `bpftool` and `bpftrace` man pages.
4. Concept 13: the Cilium rows in [cilium.md](cilium.md), and the Cilium component overview linked from the study plan.

### Drills

Short checks before any lab. Most need only a Linux VM.

- [ ] `bpftool prog show` and `bpftool map show` on any Linux host; for one program, say its type and which maps it uses
- [ ] Run three bpftrace one-liners: count system calls by process, trace TCP connects, trace packet drops
- [ ] From an example program, point to the map definition, the bounds check, and the return code, and say what happens if each is removed
- [ ] On paper, write the checks needed to read a TCP destination port from a raw packet safely
- [ ] Explain in two sentences why a hash lookup scales better than a long chain of iptables rules

### Pitfalls to know before you build

- The verifier rejects packet access that has no bounds check, and a map lookup result that is used without a null check.
- Multi-byte header fields are in network byte order. Convert before comparing.
- A program detaches when the last reference to its link is closed, unless the link is pinned. A loader that exits takes the program with it.
- Per-CPU maps return one value per CPU. Sum them in user space.
- Loading your own program on an interface that Cilium manages can conflict with it. Use a separate interface for experiments.
- A program that works on one kernel can fail to load on another. Note the kernel version in every lab.

### Readiness check

Answer each out loud without notes.

1. What does the verifier guarantee, and name two things it rejects?
2. When would you attach at XDP and when at tc?
3. What is a map, and how does user space read one?
4. What do BTF and CO-RE solve?
5. What keeps an eBPF program attached after its loader exits?
6. How would you find out which eBPF programs are attached to a pod's interface?
7. Which eBPF maps would you expect behind a Cilium Service and behind a Cilium policy decision?

## Labs

Do these after the readiness check.

- [ ] [STUDY_PLAN.md](../STUDY_PLAN.md), "eBPF and Cilium core": bpftrace one-liners, the XDP packet counter in Go, and the datapath inspection task
- [ ] [BUILD_PLAN.md](../BUILD_PLAN.md) stage 5: read the eBPF state behind one agent request
- [ ] [BUILD_PLAN.md](../BUILD_PLAN.md) stage 6, extension: the eBPF flow counter

## Sources

- [What is eBPF?](https://ebpf.io/what-is-ebpf/)
- [ebpf.io: Get started](https://ebpf.io/get-started)
- [ebpf-go: Getting started](https://ebpf-go.dev/guides/getting-started/)
- [cilium/ebpf](https://github.com/cilium/ebpf)
- [pwru](https://github.com/cilium/pwru)
