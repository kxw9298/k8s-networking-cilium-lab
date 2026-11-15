# Agent Network Security Build Plan

A build plan that sits on top of [STUDY_PLAN.md](STUDY_PLAN.md). The study plan teaches Kubernetes networking, CNI internals, eBPF, and Cilium; this plan applies those skills to one problem: controlling what AI agents can reach from inside a cluster.

Nothing in the study plan changes. Each stage below names the study plan sections it depends on, so you can run the two side by side.

## Goals, in order

1. **Get familiar.** Cilium, Go, and Kubernetes operators, and how each of them is used to run and secure AI agents. This is the first goal.
2. **Go deep.** One networking area taken past "can use it" to "can explain, build, and debug it": the Kubernetes dataplane and L7 traffic security.
3. **Contribute.** Put what you learned into an existing project instead of building a competing one.
4. **Verify.** Test the existing options against the same attacks and publish what holds and what doesn't.

Goals 2 and 3 do not depend on each other, so run them in either order once goal 1 is done.

## Core path

The stages are not equally important. Follow the core path first, and pick up an extension only when a later stage needs it. Inside each stage, tasks are grouped under **Core** and **Extensions**.

| Order | What | Why it is core |
| --- | --- | --- |
| 1 | STUDY_PLAN.md: "Linux and Kubernetes networking", "CNI internals", and "eBPF and Cilium core" | The foundation every stage here assumes, and the first Go practice |
| 2 | Stage 1: Cilium for agent workloads | The central problem, solved by hand. Publish it as soon as it works |
| 3 | Stage 2: Go fundamentals | Needed to read and write everything after it |
| 4 | Stage 3: How operators run agents | What an operator does for an agent, seen in two real projects |
| 5 | Stage 4, core tasks: operator fundamentals | Enough to read operator code |
| 6 | Stage 5, core tasks: explain the dataplane | The "explain" level of the deep dive |
| 7 | Stage 6, core tasks: the authorization service with a static allow-list | The "build" level of the deep dive, in its smallest useful form |

Stages 7 and 8 come after the core path. The "Cilium advanced" section of the study plan is an extension too, apart from its Gateway API task, which stage 6 uses.

## The deep-dive area

The area is the Kubernetes dataplane and L7 traffic security: eBPF with Cilium underneath, Envoy with Gateway API on top. It is worth going deep on for three reasons.

- **Few people cover both sides.** Network engineers rarely know Kubernetes internals, and platform engineers rarely understand the packet path.
- **It is where agent security is enforced.** Agent and MCP gateways are built on Envoy and the Gateway API, so the same skills apply directly to agent platforms.
- **It joins the other pieces.** Policy, workload identity, firewalls, and tracing all meet in this layer.

Depth here has three levels. Most people stop at the first.

| Level | You can | Where in this plan |
| --- | --- | --- |
| Use | Write FQDN and L7 policies and Gateway API routes; read Hubble flows | Stage 1, and the Gateway API task in the study plan |
| Explain | Trace a packet through the eBPF hooks; explain how identities and the FQDN-to-IP map are built, how traffic is redirected to Envoy, and how mutual TLS is established | Stage 5 |
| Build and debug | Write a small eBPF program; write an Envoy external-authorization service in Go that allows or denies an MCP tool call; find a dropped packet with kernel-level tools | Stage 6 |

## The problem

An AI agent with tool access can be steered by prompt injection into sending data somewhere it shouldn't. The model is not a security boundary, so the control has to hold even when the agent is fully compromised. The network layer gives that kind of deterministic control: an agent that can only reach its model endpoint and its approved tool servers has nowhere to send stolen data.

Standard Kubernetes NetworkPolicy matches IP addresses, not domain names, so it can't express "this agent may reach `api.example.com` and nothing else". Cilium can, with DNS-aware (`toFQDNs`) and L7 policy, which is why this plan builds on the Cilium labs.

## What already exists

Operators for agents and for agent egress already exist, so this plan does not build another one as a product. It uses them as study material in goal 1, as the place to contribute in goal 3, and as test subjects in goal 4.

| Project | What it does | How this plan uses it |
| --- | --- | --- |
| [agent-sandbox](https://github.com/kubernetes-sigs/agent-sandbox) | A Sandbox custom resource and operator for isolated agent runtimes; manages one NetworkPolicy per SandboxTemplate | Run it, read its controller, contribute to it |
| [kagent](https://kagent.dev) | Agents, model configurations, and MCP tool servers as custom resources, reconciled by an operator | Run it to see how an operator turns a custom resource into a working agent |
| [agentgateway](https://agentgateway.dev) | A gateway that understands MCP and agent-to-agent traffic and can authorize individual tools | The reference for tool-level rules at the gateway |
| Cilium | FQDN and L7 network policy, with Hubble for flow evidence | The enforcement layer in every lab |
| Small operators such as [kaalm](https://github.com/win07xp/kaalm/pull/272) and [agent-access-control](https://github.com/agentoperations/agent-access-control) | Generate egress policy for agents from an allow-list | Compare your practice operator with them, if you write one |

## How this plan uses the study plan

| Stage | Needs from STUDY_PLAN.md |
| --- | --- |
| 1. Cilium for agent workloads | "eBPF and Cilium core": Cilium installed, the policy tasks (default-deny, L7 HTTP, `toFQDNs`), and Hubble |
| 2. Go fundamentals | "CNI internals": the Go CNI plugin |
| 3. How operators run agents | Stage 1 |
| 4. Operator fundamentals | Stages 2 and 3 |
| 5. Explain the dataplane | Stage 1; "eBPF and Cilium core": the eBPF basics, bpftrace, and the datapath inspection task |
| 6. Build and debug at L7 | Stages 2 and 5; "eBPF and Cilium core": the XDP counter in Go; "Cilium advanced": the Gateway API task |
| 7. Contribute upstream | Stage 4, including its practice operator extension |
| 8. Attack suite and test matrix | Stage 3; the optional GKE Dataplane V2 cloud session and [`terraform/gke-dataplane-v2`](terraform/gke-dataplane-v2/) |

The Cluster Mesh and BGP labs are not prerequisites for any stage here. The WireGuard lab is a useful comparison for the mutual TLS task in Stage 5. Do them in whatever order suits you.

## Lab conventions

Labs for this plan go under [`labs/`](labs/) with the prefix `as` (agent security) in place of a study plan number, for example `labs/as1-agent-egress-baseline/`. Follow the same lab format as the rest of the repo, and record the versions of Cilium, agent-sandbox, kagent, and the MCP SDK each lab was run against.

## Study first, then build

Each stage has a study step and a build step, in that order. The study step is in the topic guides under [`guides/`](guides/): concepts in order, what to read, short drills, pitfalls, and a readiness check. Finish the guides listed for a stage, and pass their readiness checks, before you start that stage's labs.

| Stage | Study these guides first |
| --- | --- |
| 1. Cilium for agent workloads | [Cilium](guides/cilium.md), [MCP and agent security](guides/mcp-agent-security.md) |
| 2. Go fundamentals | [Go](guides/go.md), [gRPC](guides/grpc.md) |
| 3. How operators run agents | [Kubernetes controllers and operators](guides/kubernetes-controllers.md) |
| 4. Operator fundamentals | [Kubernetes controllers and operators](guides/kubernetes-controllers.md) |
| 5. Explain the dataplane | [eBPF](guides/ebpf.md), [Cilium](guides/cilium.md), [Envoy and Gateway API](guides/envoy-gateway-api.md) |
| 6. Build and debug at L7 | [gRPC](guides/grpc.md), [Envoy and Gateway API](guides/envoy-gateway-api.md) |
| 7. Contribute upstream | [Kubernetes controllers and operators](guides/kubernetes-controllers.md) |
| 8. Attack suite and test matrix | [MCP and agent security](guides/mcp-agent-security.md) |

The study plan's own labs follow the same rule: [Kubernetes networking](guides/kubernetes-networking.md) comes before its networking and CNI labs, and [eBPF](guides/ebpf.md) and [Cilium](guides/cilium.md) before its Cilium labs. [`guides/README.md`](guides/README.md) gives a suggested order for all eight guides.

## Goal 1: Get familiar

### Stage 1: Cilium for agent workloads

Goal: show, by hand, that a compromised agent cannot send data out.

Study first: [Cilium](guides/cilium.md) and [MCP and agent security](guides/mcp-agent-security.md).

**Core** (the whole stage)

- [ ] `as1-agent-egress-baseline`: on the base cluster, run an "agent" pod in an `agents` namespace and an MCP server in an `mcp-tools` namespace; confirm the agent can reach anything by default
- [ ] Apply default-deny egress for the agent, then allow only DNS, the model endpoint by `toFQDNs`, and the MCP server by label
- [ ] Simulate exfiltration to an unlisted domain, to the cloud metadata address, and to a Service in another namespace; capture each drop and its reason in Hubble
- [ ] Restrict which names the agent may look up, and show that DNS itself can no longer carry data out
- [ ] `as2-mcp-tool-allowlist`: since the 2026-07-28 MCP specification, Streamable HTTP requests carry the method and tool name in the `Mcp-Method` and `Mcp-Name` headers. Add an L7 HTTP rule on the MCP server port that matches them; confirm an unlisted tool call is refused while `tools/list` and the allowed tools still work. Check the exact rule syntax against the Cilium docs for your version
- [ ] Send a request whose `Mcp-Name` header names an allowed tool while the body calls another; record whether the server rejects it, as the specification requires
- [ ] Checkpoint: explain why an IP-based NetworkPolicy cannot do this, and where each blocked request was dropped
- [ ] Publish: commit the `as1` and `as2` write-ups and mark stage 1 done in the progress table below, so there is something to show early

### Stage 2: Go fundamentals

Goal: read and write everyday Go without looking things up.

Study first: [Go](guides/go.md), then [gRPC](guides/grpc.md) before the gRPC task.

**Core** (the whole stage)

- [ ] Finish [A Tour of Go](https://go.dev/tour/)
- [ ] Add table-driven tests to the Go CNI plugin from the study plan
- [ ] Practise the parts operators lean on: interfaces, error wrapping, `context`, goroutines and channels, and struct tags for JSON and YAML
- [ ] Write a small client-go program that watches pods with an informer and prints changes
- [ ] gRPC basics: define a small service in protobuf, generate the Go code, and write a client and server for one call. The Envoy authorizer in stage 6 uses the same pattern
- [ ] Checkpoint: explain what an informer caches, and why you read from the cache instead of calling the API server each time

### Stage 3: How operators run agents

Goal: see what an operator does for an AI agent before you write one.

Study first: [Kubernetes controllers and operators](guides/kubernetes-controllers.md).

**Core**

- [ ] `as3-agent-sandbox`: install a pinned agent-sandbox release; create a SandboxTemplate and a claim; list every object the operator created and the NetworkPolicy it manages
- [ ] Create a Sandbox directly and confirm it gets no NetworkPolicy; layer an FQDN policy on top with Cilium
- [ ] Delete a sandbox pod and watch the operator bring it back; follow the reconcile in the controller logs
- [ ] `as4-kagent`: install a pinned kagent release; create a model configuration, an MCP server, and an agent as custom resources. It needs a model provider: use a small local model, or an API key kept out of the repo
- [ ] Trace one agent request in Hubble: agent to model endpoint, agent to MCP server. Then apply the Stage 1 policy to it, break it on purpose, and fix it
- [ ] Read agent-sandbox's controller code for the SandboxTemplate NetworkPolicy; note how it uses owner references, status, and labels
- [ ] Checkpoint: for one custom resource in each project, explain what the operator watches, what it creates, and what it writes to status

**Extensions**

- [ ] Run one sandbox under the gVisor RuntimeClass and repeat the FQDN test

### Stage 4: Operator fundamentals

Goal: understand the operator pattern well enough to read one. Writing your own is an extension, and becomes necessary before you contribute to operator code in stage 7.

Study first: [Kubernetes controllers and operators](guides/kubernetes-controllers.md), if not already done for stage 3.

**Core**

- [ ] Work through the [Kubebuilder](https://book.kubebuilder.io) quick start and its CronJob tutorial
- [ ] Read the [controller-runtime](https://github.com/kubernetes-sigs/controller-runtime) docs on reconcilers, owner references, finalizers, status conditions, and envtest
- [ ] Checkpoint: explain informer, work queue, and reconcile loop, and why a reconciler must be level-triggered and idempotent

**Extensions: a practice operator**

This is a learning prototype, not a product.

- [ ] `as5-practice-operator`: scaffold an operator with one custom resource, `AgentEgressPolicy`, that lists what an agent may reach
- [ ] Reconcile it into a `CiliumNetworkPolicy` owned by the custom resource: DNS rule, `toFQDNs`, and endpoint rules
- [ ] Set a status condition that says whether the policy is enforced, with a reason when the cluster has no Cilium CRDs
- [ ] envtest coverage for create, update, and delete; then rerun the Stage 1 exfiltration test against a policy your operator generated
- [ ] Compare your design with kaalm's FQDN synthesis and agent-sandbox's managed NetworkPolicy; write down what they do better

A minimal shape for the custom resource:

```yaml
apiVersion: agentsecurity.example.dev/v1alpha1
kind: AgentEgressPolicy
metadata:
  name: research-agent
  namespace: agents
spec:
  podSelector:
    matchLabels: {app: research-agent}
  fqdns: [api.anthropic.com]
  mcpServers:
    - service: {name: github-mcp, namespace: mcp-tools, port: 8080}
status:
  conditions:
    - type: NetworkEnforced
```

## Goal 2: Go deep

### Stage 5: Explain the dataplane

Goal: explain, from the kernel up, what happens to one agent request.

Study first: [eBPF](guides/ebpf.md), [Cilium](guides/cilium.md), and [Envoy and Gateway API](guides/envoy-gateway-api.md).

**Core**

- [ ] `as6-dataplane-walkthrough`: pick one request from the Stage 1 lab (agent to MCP server) and trace it hop by hop: pod veth, the eBPF programs on it, the policy lookup, the redirect to Envoy for L7, and the reply path
- [ ] Identities: list the security identities Cilium gave the agent and the MCP server, change a label, and watch the identity and the policy verdict change
- [ ] FQDN policy internals: watch the DNS proxy see a lookup, find the FQDN-to-IP entry it created, and show what happens when the record's TTL expires
- [ ] Read the eBPF state behind a decision: the policy map for the agent's endpoint, the connection-tracking entry for the flow, and the Service load-balancing map. Use `cilium-dbg` and `bpftool`, and check the command names against your Cilium version
- [ ] L7 path: confirm which Envoy handles the agent's HTTP request, read the listener and filter configuration it was given, and find the access log entry for one allowed and one denied call
- [ ] Draw the whole path as one diagram, with the hook or component that makes each decision
- [ ] Checkpoint: explain to someone else, without notes, why an FQDN rule keeps working when the destination's IP address changes

**Extensions**

- [ ] Mutual TLS: give two workloads identities with a mesh or Cilium's ztunnel integration (beta at the time of writing), capture the traffic, and show what an observer on the node can and cannot see. Compare it with the WireGuard lab

### Stage 6: Build and debug at L7

Goal: write code that sits in the traffic path, and find faults in it.

Study first: [gRPC](guides/grpc.md) and [Envoy and Gateway API](guides/envoy-gateway-api.md).

**Core**

- [ ] `as8-mcp-ext-authz`: write an Envoy external-authorization service in Go. It receives the request headers, reads `Mcp-Method` and `Mcp-Name` and the caller's identity, and answers allow or deny from a static allow-list
- [ ] Put it in front of the MCP server through an Envoy-based Gateway API implementation that supports external authorization; record which one you used and how you wired it
- [ ] Decide what happens when the authorizer is slow or down, and test it
- [ ] Checkpoint: an allowed tool call succeeds and an unlisted one is denied at the gateway, with a test that proves both

**Extensions**

- [ ] Move the decision into a policy engine such as Open Policy Agent so rules change without a rebuild
- [ ] Have the service read the request body as well, and reject any request whose headers and body disagree
- [ ] Add a decision log and metrics, and carry the trace context through so one tool call shows up as one trace across agent, gateway, authorizer, and MCP server
- [ ] Compare your service with agentgateway's built-in MCP authorization; write down what it does that yours does not
- [ ] `as7-ebpf-flow-counter`: extend the XDP counter from the study plan into a small eBPF program, loaded from Go with [`cilium/ebpf`](https://github.com/cilium/ebpf), that counts connections per destination on the veth of one of the hand-built namespaces
- [ ] `as9-fault-finding`: break the path on purpose, one fault at a time (a wrong policy, a DNS rule that is too tight, an MTU mismatch, an authorizer that times out), and find each one with Hubble, `cilium-dbg monitor`, and [`pwru`](https://github.com/cilium/pwru). Keep the steps as a troubleshooting runbook
- [ ] Checkpoint for the runbook: given a dropped or denied request you have not seen before, say which layer stopped it within a few minutes

## Goal 3: Contribute

### Stage 7: Contribute upstream

Goal: get a change reviewed and merged in a project people already use. Reviews take a while, so start small. This stage comes after the core path; do the practice operator extension in stage 4 before you touch controller code.

Study first: [Kubernetes controllers and operators](guides/kubernetes-controllers.md).

- [ ] Read the agent-sandbox contributing guide and follow its issue tracker; note any documentation or example gap you hit in Stage 3
- [ ] Open a small pull request, for example a Cilium FQDN egress example next to the project's existing network policy examples
- [ ] Pick up a small bug or test task in the controller code
- [ ] If you needed a feature in the labs, open a design discussion for it, with your practice operator as the working reference if you built one
- [ ] Checkpoint: one merged pull request

## Goal 4: Verify

### Stage 8: Attack suite and test matrix

Goal: prove what each existing option stops, and say plainly what it doesn't. This stage comes after the core path.

Study first: [MCP and agent security](guides/mcp-agent-security.md).

- [ ] Attack suite: one scripted scenario per threat (unlisted domain, metadata address, cross-namespace Service, DNS exfiltration, unlisted tool, header and body mismatch), each with an expected result
- [ ] Run it against each option: plain NetworkPolicy, agent-sandbox's managed policy, Cilium FQDN and L7 policy, tool rules at agentgateway, and your external-authorization service if you have built it
- [ ] GKE session: create the cluster with [`terraform/gke-dataplane-v2`](terraform/gke-dataplane-v2/), enable FQDN network policy on it with `gcloud container clusters update`, run the suite, and destroy the cluster the same day
- [ ] Confirm whether GKE Dataplane V2 accepts Cilium L7 rules, and record the result
- [ ] Add container runtime to the matrix: runc and gVisor. One project reports that FQDN policy does not work with Kata guests; test it if you can, and record the result either way
- [ ] Checkpoint: publish the matrix as a table, with a short write-up of anything that surprised you

## Design notes to carry through the labs

- **Network layer versus gateway.** The network layer answers "which hosts can this agent reach". Tool-level rules can also be enforced there for in-cluster MCP servers over HTTP. For external MCP servers over TLS, and on platforms without L7 policy, tool-level rules belong in an MCP-aware gateway.
- **Header trust.** `Mcp-Name` is set by the client. A rule that matches it holds only if the MCP server rejects requests whose headers and body disagree.
- **Fail closed.** Give agent namespaces a baseline deny-all egress policy and add allows on top, so an agent with no policy has no egress.

## Use cases

| Use case | What you build | Skill area | What it demonstrates |
| --- | --- | --- | --- |
| A prompt-injected agent tries to send data out | Default-deny egress with an FQDN allow-list, and Hubble evidence of the drop | Agent security, Cilium policy | A control that holds when the agent is compromised |
| An agent calls a tool it shouldn't | L7 rule on the `Mcp-Name` header for in-cluster MCP servers | MCP, L7 policy | Per-tool authorization below the application |
| "What did the operator create for this agent?" | agent-sandbox and kagent labs | Kubernetes operators | Reading an operator from its custom resources and logs |
| A sandbox created without a policy | Baseline deny-all in agent namespaces | Secure defaults | Failing closed instead of open |
| Policy as an API | The practice operator | Go, operators | Extending Kubernetes instead of hand-writing YAML |
| "Why was this request dropped?" | The dataplane walkthrough and the fault-finding runbook | eBPF, Cilium internals, troubleshooting | Naming the layer that stopped a request, with evidence |
| Authorizing a tool call at the gateway | The external-authorization service | Go, Envoy, Gateway API, policy engines | Code in the traffic path that decides per identity and per tool |
| One tool call, one trace | Trace context carried through gateway and authorizer | Observability | Following a request across network and application layers |
| Which option stops which attack | The attack suite and matrix | Security evaluation | Choosing between existing tools with evidence |

## Risks and open questions

- **Scope.** The two plans together are large. Follow the core path, and leave an extension alone until a later stage needs it.
- **L7 header matching is unproven here.** Stage 1 tests it before anything else depends on it.
- **GKE Dataplane V2 limits.** Reports say it rejects Cilium L7 rules, and FQDN network policy has its own requirements. Verify both in the GKE session.
- **Fast-moving projects.** agent-sandbox and kagent release often, so pin a release for each lab and note it.
- **Custom eBPF next to Cilium.** Loading your own program on an interface Cilium manages can conflict with it. Stage 6 uses the hand-built namespaces for that reason.
- **External authorization differs by gateway.** Each Gateway API implementation wires it up its own way, and some don't support it. Check before you choose one.
- **ztunnel is beta.** The mutual TLS task may change between Cilium releases; a service mesh is the fallback.
- **Upstream timing.** A merge is not in your control. The labs and the matrix stand on their own.
- **Cost.** Stop the lab VM between sessions and destroy cloud clusters the same day, as in the study plan.

## Self-check questions

Answer each of these out loud without notes.

1. Why can't a standard NetworkPolicy express "this agent may reach only one domain", and how does Cilium make it possible?
2. An agent pod sends a request to an unlisted domain. Where is it dropped, and how do you prove it?
3. Why must DNS be allowed for FQDN policy to work, how can DNS itself leak data, and how do you limit that?
4. Since the 2026-07-28 MCP specification, where does the tool name travel, and when can a network policy trust it?
5. Which controls belong at the network layer and which at a gateway, and what changes on GKE Dataplane V2?
6. Explain an informer, a work queue, and a reconcile loop. Why level-triggered, and why idempotent?
7. When do you use an owner reference, and when a finalizer?
8. When you create an agent in kagent, what does the operator create, and what does it report in status?
9. How does agent-sandbox manage network policy, and what happens to a Sandbox created directly?
10. A prompt-injected agent holds valid credentials for one MCP server. Which controls still limit the damage, and which do not?
11. Follow one HTTP request from an agent pod to an MCP server on another node. Which eBPF programs and maps does it touch, and where does Envoy come in?
12. How does Cilium turn pod labels into a security identity, and why does policy by identity survive a pod restart with a new IP?
13. What does an Envoy external-authorization service receive, what can it answer, and what should happen when it is slow or down?
14. What does mutual TLS between workloads prove that node-to-node encryption does not?

## Progress

| Goal | Stage | Focus | Core path | Status |
| --- | --- | --- | --- | --- |
| Get familiar | 1 | Cilium for agent workloads | Whole stage | Not started |
| Get familiar | 2 | Go fundamentals | Whole stage | Not started |
| Get familiar | 3 | How operators run agents | Core tasks | Not started |
| Get familiar | 4 | Operator fundamentals | Core tasks | Not started |
| Go deep | 5 | Explain the dataplane | Core tasks | Not started |
| Go deep | 6 | Build and debug at L7 | Core tasks | Not started |
| Contribute | 7 | Contribute upstream | After the core path | Not started |
| Verify | 8 | Attack suite and test matrix | After the core path | Not started |

## Sources

- [MCP specification 2026-07-28: key changes](https://modelcontextprotocol.io/specification/2026-07-28/changelog)
- [MCP blog: The 2026-07-28 Specification](https://blog.modelcontextprotocol.io/posts/2026-07-28/)
- [agent-sandbox](https://github.com/kubernetes-sigs/agent-sandbox) and its [releases](https://github.com/kubernetes-sigs/agent-sandbox/releases)
- [agent-sandbox: network policy management](https://github.com/kubernetes-sigs/agent-sandbox/blob/main/examples/policy/network-policy-management/README.md)
- [Kubernetes blog: Running Agents on Kubernetes with Agent Sandbox](https://kubernetes.io/blog/2026/03/20/running-agents-on-kubernetes-with-agent-sandbox)
- [kagent](https://kagent.dev)
- [agentgateway](https://agentgateway.dev)
- [GKE: Control Pod egress traffic using FQDN network policies](https://docs.cloud.google.com/kubernetes-engine/docs/how-to/fqdn-network-policies)
- [O'Reilly Radar: Prompt Injection to Data Exfil in 3 Hops](https://www.oreilly.com/radar/prompt-injection-to-data-exfil-in-3-hops/)
- [Report on FQDN policy with Kata guests](https://github.com/sabbour/agentweaver/issues/2631)
- [Kubebuilder book](https://book.kubebuilder.io)
- [controller-runtime](https://github.com/kubernetes-sigs/controller-runtime)
- [A Tour of Go](https://go.dev/tour/)
- [cilium/ebpf](https://github.com/cilium/ebpf)
- [pwru](https://github.com/cilium/pwru)
- [Envoy](https://www.envoyproxy.io)
- [Open Policy Agent](https://www.openpolicyagent.org)
