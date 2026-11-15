# Topic study guides

One guide per topic. Each has the same two parts, and the order matters.

1. **Study.** Concepts in order, what to read for each, short drills, and the pitfalls to know. It ends with a readiness check.
2. **Labs.** The hands-on work, which lives in [STUDY_PLAN.md](../STUDY_PLAN.md) and [BUILD_PLAN.md](../BUILD_PLAN.md).

Finish a guide's Study part and pass its readiness check before you start the labs that depend on it. The drills are part of studying: they are small, and most need only paper or one terminal.

## Guides

| Topic | Guide | Study it before |
| --- | --- | --- |
| Networking basics, Linux networking, Services, DNS, NetworkPolicy, CNI | [kubernetes-networking.md](kubernetes-networking.md) | STUDY_PLAN.md: "Linux and Kubernetes networking" and "CNI internals" |
| eBPF | [ebpf.md](ebpf.md) | STUDY_PLAN.md: "eBPF and Cilium core"; BUILD_PLAN.md stages 5 and 6 |
| Cilium | [cilium.md](cilium.md) | STUDY_PLAN.md: "eBPF and Cilium core" and "Cilium advanced"; BUILD_PLAN.md stages 1 and 5 |
| MCP and agent security | [mcp-agent-security.md](mcp-agent-security.md) | BUILD_PLAN.md stages 1, 3, 6, and 8 |
| Go | [go.md](go.md) | STUDY_PLAN.md: the Go CNI plugin; BUILD_PLAN.md stage 2 and every stage after it |
| gRPC | [grpc.md](grpc.md) | BUILD_PLAN.md stage 2 (gRPC task) and stage 6 |
| Kubernetes controllers and operators | [kubernetes-controllers.md](kubernetes-controllers.md) | BUILD_PLAN.md stages 3, 4, and 7 |
| Envoy and Gateway API | [envoy-gateway-api.md](envoy-gateway-api.md) | BUILD_PLAN.md stages 5 and 6 |

## Suggested order

There are two ways to follow it. Study every guide first, top to bottom, and then do the labs in the "Then build" column in the same order. Or go row by row: study one row, then build it, before the next row. Either way, no lab starts before the guides it depends on.

| Order | Study | Then build |
| --- | --- | --- |
| 1 | Kubernetes networking | STUDY_PLAN.md: "Linux and Kubernetes networking" |
| 2 | Go | STUDY_PLAN.md: "CNI internals", including the Go plugin |
| 3 | eBPF, then Cilium | STUDY_PLAN.md: "eBPF and Cilium core" |
| 4 | MCP and agent security | BUILD_PLAN.md stage 1 |
| 5 | gRPC | BUILD_PLAN.md stage 2 |
| 6 | Kubernetes controllers and operators | BUILD_PLAN.md stages 3 and 4 |
| 7 | Envoy and Gateway API | BUILD_PLAN.md stages 5 and 6 |

The guides add no new labs. Every item under a guide's Labs heading points to a task that already exists in one of the two plans.
