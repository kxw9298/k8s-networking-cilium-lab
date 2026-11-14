# Agent Network Security Build Plan

A build plan that sits on top of [STUDY_PLAN.md](STUDY_PLAN.md). The study plan teaches Kubernetes networking, CNI internals, eBPF, and Cilium; this plan applies those skills to one problem: controlling what AI agents can reach from inside a cluster.

Nothing in the study plan changes. Each stage below names the study plan sections it depends on, so you can run the two side by side.

## Goals, in order

1. **Get familiar.** Cilium, Go, and Kubernetes operators, and how each of them is used to run and secure AI agents. This is the first goal, and most of the plan.
2. **Contribute.** Put what you learned into an existing project instead of building a competing one.
3. **Verify.** Test the existing options against the same attacks and publish what holds and what doesn't.

## The problem

An AI agent with tool access can be steered by prompt injection into sending data somewhere it shouldn't. The model is not a security boundary, so the control has to hold even when the agent is fully compromised. The network layer gives that kind of deterministic control: an agent that can only reach its model endpoint and its approved tool servers has nowhere to send stolen data.

Standard Kubernetes NetworkPolicy matches IP addresses, not domain names, so it can't express "this agent may reach `api.example.com` and nothing else". Cilium can, with DNS-aware (`toFQDNs`) and L7 policy, which is why this plan builds on the Cilium labs.

## What already exists

Operators for agents and for agent egress already exist, so this plan does not build another one as a product. It uses them as study material in goal 1, as the place to contribute in goal 2, and as test subjects in goal 3.

| Project | What it does | How this plan uses it |
| --- | --- | --- |
| [agent-sandbox](https://github.com/kubernetes-sigs/agent-sandbox) | A Sandbox custom resource and operator for isolated agent runtimes; manages one NetworkPolicy per SandboxTemplate | Run it, read its controller, contribute to it |
| [kagent](https://kagent.dev) | Agents, model configurations, and MCP tool servers as custom resources, reconciled by an operator | Run it to see how an operator turns a custom resource into a working agent |
| [agentgateway](https://agentgateway.dev) | A gateway that understands MCP and agent-to-agent traffic and can authorize individual tools | The reference for tool-level rules at the gateway |
| Cilium | FQDN and L7 network policy, with Hubble for flow evidence | The enforcement layer in every lab |
| Small operators such as [kaalm](https://github.com/win07xp/kaalm/pull/272) and [agent-access-control](https://github.com/agentoperations/agent-access-control) | Generate egress policy for agents from an allow-list | Compare your practice operator with them after you write it |

## How this plan uses the study plan

| Stage | Needs from STUDY_PLAN.md |
| --- | --- |
| 1. Cilium for agent workloads | "eBPF and Cilium core": Cilium installed, the policy tasks (default-deny, L7 HTTP, `toFQDNs`), and Hubble |
| 2. Go fundamentals | "CNI internals": the Go CNI plugin |
| 3. How operators run agents | Stage 1 |
| 4. Write a practice operator | Stages 2 and 3 |
| 5. Contribute upstream | Stage 4 |
| 6. Attack suite and test matrix | Stage 3; the optional GKE Dataplane V2 cloud session and [`terraform/gke-dataplane-v2`](terraform/gke-dataplane-v2/) |

The Cluster Mesh, BGP, WireGuard, and Gateway API labs are not prerequisites for any stage here. Do them in whatever order suits you.

## Lab conventions

Labs for this plan go under [`labs/`](labs/) with the prefix `as` (agent security) in place of a study plan number, for example `labs/as1-agent-egress-baseline/`. Follow the same lab format as the rest of the repo, and record the versions of Cilium, agent-sandbox, kagent, and the MCP SDK each lab was run against.

## Goal 1: Get familiar

### Stage 1: Cilium for agent workloads

Goal: show, by hand, that a compromised agent cannot send data out.

- [ ] `as1-agent-egress-baseline`: on the base cluster, run an "agent" pod in an `agents` namespace and an MCP server in an `mcp-tools` namespace; confirm the agent can reach anything by default
- [ ] Apply default-deny egress for the agent, then allow only DNS, the model endpoint by `toFQDNs`, and the MCP server by label
- [ ] Simulate exfiltration to an unlisted domain, to the cloud metadata address, and to a Service in another namespace; capture each drop and its reason in Hubble
- [ ] Restrict which names the agent may look up, and show that DNS itself can no longer carry data out
- [ ] `as2-mcp-tool-allowlist`: since the 2026-07-28 MCP specification, Streamable HTTP requests carry the method and tool name in the `Mcp-Method` and `Mcp-Name` headers. Add an L7 HTTP rule on the MCP server port that matches them; confirm an unlisted tool call is refused while `tools/list` and the allowed tools still work. Check the exact rule syntax against the Cilium docs for your version
- [ ] Send a request whose `Mcp-Name` header names an allowed tool while the body calls another; record whether the server rejects it, as the specification requires
- [ ] Checkpoint: explain why an IP-based NetworkPolicy cannot do this, and where each blocked request was dropped

### Stage 2: Go fundamentals

Goal: read and write everyday Go without looking things up.

- [ ] Finish [A Tour of Go](https://go.dev/tour/)
- [ ] Add table-driven tests to the Go CNI plugin from the study plan
- [ ] Practise the parts operators lean on: interfaces, error wrapping, `context`, goroutines and channels, and struct tags for JSON and YAML
- [ ] Write a small client-go program that watches pods with an informer and prints changes
- [ ] Checkpoint: explain what an informer caches, and why you read from the cache instead of calling the API server each time

### Stage 3: How operators run agents

Goal: see what an operator does for an AI agent before you write one.

- [ ] `as3-agent-sandbox`: install a pinned agent-sandbox release; create a SandboxTemplate and a claim; list every object the operator created and the NetworkPolicy it manages
- [ ] Create a Sandbox directly and confirm it gets no NetworkPolicy; layer an FQDN policy on top with Cilium
- [ ] Delete a sandbox pod and watch the operator bring it back; follow the reconcile in the controller logs
- [ ] `as4-kagent`: install a pinned kagent release; create a model configuration, an MCP server, and an agent as custom resources. It needs a model provider: use a small local model, or an API key kept out of the repo
- [ ] Trace one agent request in Hubble: agent to model endpoint, agent to MCP server. Then apply the Stage 1 policy to it, break it on purpose, and fix it
- [ ] Read agent-sandbox's controller code for the SandboxTemplate NetworkPolicy; note how it uses owner references, status, and labels
- [ ] Optional: run one sandbox under the gVisor RuntimeClass and repeat the FQDN test
- [ ] Checkpoint: for one custom resource in each project, explain what the operator watches, what it creates, and what it writes to status

### Stage 4: Write a practice operator

Goal: write a small operator yourself, to learn the pattern. This is a learning prototype, not a product.

- [ ] Work through the [Kubebuilder](https://book.kubebuilder.io) quick start and its CronJob tutorial
- [ ] Read the [controller-runtime](https://github.com/kubernetes-sigs/controller-runtime) docs on reconcilers, owner references, finalizers, status conditions, and envtest
- [ ] `as5-practice-operator`: scaffold an operator with one custom resource, `AgentEgressPolicy`, that lists what an agent may reach
- [ ] Reconcile it into a `CiliumNetworkPolicy` owned by the custom resource: DNS rule, `toFQDNs`, and endpoint rules
- [ ] Set a status condition that says whether the policy is enforced, with a reason when the cluster has no Cilium CRDs
- [ ] envtest coverage for create, update, and delete; then rerun the Stage 1 exfiltration test against a policy your operator generated
- [ ] Compare your design with kaalm's FQDN synthesis and agent-sandbox's managed NetworkPolicy; write down what they do better
- [ ] Checkpoint: explain informer, work queue, and reconcile loop, and why a reconciler must be level-triggered and idempotent

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

## Goal 2: Contribute

### Stage 5: Contribute upstream

Goal: get a change reviewed and merged in a project people already use. Reviews take a while, so start small.

- [ ] Read the agent-sandbox contributing guide and follow its issue tracker; note any documentation or example gap you hit in Stage 3
- [ ] Open a small pull request, for example a Cilium FQDN egress example next to the project's existing network policy examples
- [ ] Pick up a small bug or test task in the controller code
- [ ] If you needed a feature in the labs, open a design discussion for it, with your practice operator as the working reference
- [ ] Checkpoint: one merged pull request

## Goal 3: Verify

### Stage 6: Attack suite and test matrix

Goal: prove what each existing option stops, and say plainly what it doesn't.

- [ ] Attack suite: one scripted scenario per threat (unlisted domain, metadata address, cross-namespace Service, DNS exfiltration, unlisted tool, header and body mismatch), each with an expected result
- [ ] Run it against each option: plain NetworkPolicy, agent-sandbox's managed policy, Cilium FQDN and L7 policy, and tool rules at agentgateway
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
| Which option stops which attack | The attack suite and matrix | Security evaluation | Choosing between existing tools with evidence |

## Risks and open questions

- **L7 header matching is unproven here.** Stage 1 tests it before anything else depends on it.
- **GKE Dataplane V2 limits.** Reports say it rejects Cilium L7 rules, and FQDN network policy has its own requirements. Verify both in the GKE session.
- **Fast-moving projects.** agent-sandbox and kagent release often, so pin a release for each lab and note it.
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

## Progress

| Goal | Stage | Focus | Status |
| --- | --- | --- | --- |
| Get familiar | 1 | Cilium for agent workloads | Not started |
| Get familiar | 2 | Go fundamentals | Not started |
| Get familiar | 3 | How operators run agents | Not started |
| Get familiar | 4 | Write a practice operator | Not started |
| Contribute | 5 | Contribute upstream | Not started |
| Verify | 6 | Attack suite and test matrix | Not started |

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
