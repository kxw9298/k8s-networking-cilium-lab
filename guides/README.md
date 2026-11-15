# Topic study guides

One guide per topic. The guides are short on purpose: each covers the fundamentals of its topic and stops there. After studying a guide, you should be able to answer the questions at the end of its Study part. That is the measure of "understood".

Each guide has the same two parts, and the order matters.

1. **Study.** Key fundamentals, what to read for them, a few short drills, the pitfalls to know, and the questions you should be able to answer, each with what a strong answer covers. A "Go further" list at the end is optional.
2. **Labs.** The hands-on work, which lives in [STUDY_PLAN.md](../STUDY_PLAN.md) and [BUILD_PLAN.md](../BUILD_PLAN.md).

Finish a guide's Study part, and be able to answer its questions out loud, before you start the labs that depend on it. The drills are part of studying: they are small, and most need only paper or one terminal.

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

## Using the questions

- Answer out loud, without notes, in about two minutes per question. Saying it is harder than reading it, and it shows what you actually know.
- Structure each answer the same way: one sentence that answers the question, then how it works, then a trade-off or a failure you have seen.
- Draw while you talk when the question is a trace or a design.
- The "A strong answer covers" column is a checklist to compare against afterwards, not a script to memorise.
- After a lab, answer the same questions again and add what you saw: a command, an output, a failure. An answer with a concrete detail from your own cluster is stronger than a correct one without it.

## Questions that cross topics

These combine several guides. Try them once all the guides are done, and again after the labs.

1. Trace one tool call from an agent pod to an MCP server in another namespace. Name every component that can allow or deny it, and what each one can see.
2. Compare enforcing a rule in a NetworkPolicy, in a Cilium L7 policy, at a gateway with external authorization, and in the application. What does each see, and what does each miss?
3. An agent can reach the model API, but its tool calls time out. Find the cause, working layer by layer.
4. You are asked to move a cluster from kube-proxy and iptables to an eBPF dataplane. What do you check first, and how do you roll it out?
5. Design a platform for running AI agents for several teams on Kubernetes, and say which parts you would build, which you would adopt, and how you would prove the controls work.
