# Agent Network Security Build Plan

A build plan that sits on top of [STUDY_PLAN.md](STUDY_PLAN.md). The study plan teaches Kubernetes networking, CNI internals, eBPF, and Cilium; this plan applies those skills to one problem: controlling what AI agents can reach from inside a cluster. It adds Go and Kubernetes controller practice, and ends with a working open-source controller.

Nothing in the study plan changes. Each stage below names the study plan sections it depends on, so you can run the two side by side.

## The problem

An AI agent with tool access can be steered by prompt injection into sending data somewhere it shouldn't. The model is not a security boundary, so the control has to hold even when the agent is fully compromised. The network layer gives that kind of deterministic control: an agent that can only reach its model endpoint and its approved tool servers has nowhere to send stolen data.

Standard Kubernetes NetworkPolicy matches IP addresses, not domain names, so it can't express "this agent may reach `api.example.com` and nothing else". Cilium can, with DNS-aware (`toFQDNs`) and L7 policy, which is why this plan builds on the Cilium labs.

## What you build

Working name: `agent-egress-policy`. One custom resource per agent declares what that agent may reach. A controller written in Go turns it into enforced policy and reports what is actually enforced.

```yaml
apiVersion: agentsecurity.example.dev/v1alpha1
kind: AgentEgressPolicy
metadata:
  name: research-agent
  namespace: agents
spec:
  podSelector:
    matchLabels: {app: research-agent}   # or sandboxTemplateRef
  models:
    - fqdn: api.anthropic.com
  mcpServers:
    - service: {name: github-mcp, namespace: mcp-tools, port: 8080}
      allowedTools: [search_issues, get_file]
    - fqdn: mcp.partner.example          # external: host-level only
status:
  backend: cilium
  conditions:
    - type: NetworkEnforced
    - type: ToolFilterEnforced
```

The controller lives in its own repository so it has a clean history, CI, and releases. The labs that lead up to it stay in this repo.

### Prior art, and what is different here

Generating a Cilium FQDN policy from an allow-list is not new. [agent-sandbox](https://github.com/kubernetes-sigs/agent-sandbox) manages a NetworkPolicy per SandboxTemplate, and small operators such as [kaalm](https://github.com/win07xp/kaalm/pull/272) and [agent-access-control](https://github.com/agentoperations/agent-access-control) already synthesize egress policy for agents. This project is worth building only if it does more than that:

| Difference | Why it matters |
| --- | --- |
| Binds to agent-sandbox | agent-sandbox keeps one shared NetworkPolicy per SandboxTemplate, and a Sandbox created directly gets none, so per-agent rules and FQDN rules are left to you |
| MCP-aware | Since the 2026-07-28 MCP specification, Streamable HTTP requests carry the method and tool name in the `Mcp-Method` and `Mcp-Name` headers, so an L7 policy can allow individual tools without parsing the body |
| More than one backend | Cilium on self-managed clusters; `FQDNNetworkPolicy` on GKE Dataplane V2. The status conditions say which controls the cluster can really enforce |
| Verified | An automated attack suite proves that exfiltration and unlisted tool calls are blocked, and denied attempts are reported per agent from Hubble |

### Design boundaries

- **Network layer versus gateway.** The network layer answers "which hosts can this agent reach". Tool-level rules can also be enforced there for in-cluster MCP servers over HTTP. For external MCP servers over TLS, and on platforms without L7 policy, tool-level rules belong in an MCP-aware gateway.
- **Header trust.** `Mcp-Name` is set by the client. A rule that matches it holds only if the MCP server rejects requests whose headers and body disagree, which the specification requires. Test that your server does.
- **Fail closed.** A namespace labelled for agents gets a baseline deny-all egress policy. An `AgentEgressPolicy` adds allows on top, so an agent with no policy has no egress.

## How this plan uses the study plan

| Stage | Needs from STUDY_PLAN.md |
| --- | --- |
| 1. Agent egress on Cilium | "eBPF and Cilium core": Cilium installed, the policy tasks (default-deny, L7 HTTP, `toFQDNs`), and Hubble |
| 2. Go and controller fundamentals | "CNI internals": the Go CNI plugin |
| 3. Controller v0.1 | Stages 1 and 2 |
| 4. Controller v0.2 | Stage 3 |
| 5. Second backend and verification | Stage 4; the optional GKE Dataplane V2 cloud session and [`terraform/gke-dataplane-v2`](terraform/gke-dataplane-v2/) |
| 6. Publish | Stage 5 |

The Cluster Mesh, BGP, WireGuard, and Gateway API labs are not prerequisites for any stage here. Do them in whatever order suits you.

## Stages

Labs for this plan go under [`labs/`](labs/) with the prefix `as` (agent security) in place of a study plan number, for example `labs/as1-agent-egress-baseline/`. Follow the same lab format as the rest of the repo, and record the Cilium, agent-sandbox, and MCP SDK versions each lab was run against.

### Stage 1: Agent egress on Cilium

Goal: show, by hand, that a compromised agent cannot send data out.

- [ ] `as1-agent-egress-baseline`: on the base cluster, run an "agent" pod in an `agents` namespace and an MCP server in an `mcp-tools` namespace; confirm the agent can reach anything by default
- [ ] Apply default-deny egress for the agent, then allow only DNS, the model endpoint by `toFQDNs`, and the MCP server by label
- [ ] Simulate exfiltration to an unlisted domain, to the cloud metadata address, and to a Service in another namespace; capture each drop and its reason in Hubble
- [ ] Restrict which names the agent may look up, and show that DNS itself can no longer carry data out
- [ ] `as2-mcp-tool-allowlist`: add an L7 HTTP rule on the MCP server port that matches `Mcp-Method` and `Mcp-Name`; confirm an unlisted tool call is refused while `tools/list` and the allowed tools still work. Treat this as a feasibility spike and check the exact rule syntax against the Cilium docs for your version
- [ ] Send a request whose `Mcp-Name` header names an allowed tool while the body calls another; record whether the server rejects it
- [ ] `as3-agent-sandbox-policy`: install a pinned agent-sandbox release; create a SandboxTemplate and read the NetworkPolicy it manages; create a Sandbox directly and confirm it gets no policy; layer an FQDN policy on top
- [ ] Optional: run one sandbox under the gVisor RuntimeClass and repeat the FQDN test
- [ ] Checkpoint: explain why an IP-based NetworkPolicy cannot do this, and where each blocked request was dropped

### Stage 2: Go and controller fundamentals

Goal: read and write controller code with confidence.

- [ ] Finish [A Tour of Go](https://go.dev/tour/), then add table-driven tests to the Go CNI plugin from the study plan
- [ ] Write a small client-go program that watches pods with an informer and prints changes
- [ ] Work through the [Kubebuilder](https://book.kubebuilder.io) quick start and its CronJob tutorial
- [ ] Read how agent-sandbox's controller manages the SandboxTemplate NetworkPolicy; note how it uses owner references, status, and labels
- [ ] Read the [controller-runtime](https://github.com/kubernetes-sigs/controller-runtime) docs on reconcilers, finalizers, status conditions, and envtest
- [ ] Checkpoint: explain informer, work queue, and reconcile loop, and why a reconciler must be level-triggered and idempotent

### Stage 3: Controller v0.1, FQDN egress

Goal: one custom resource in, enforced Cilium policy out.

- [ ] Create the `agent-egress-policy` repository and scaffold it with Kubebuilder
- [ ] Define `AgentEgressPolicy` v1alpha1: pod selector, models, MCP servers, extra FQDNs
- [ ] Reconcile it into a `CiliumNetworkPolicy`: DNS rule, `toFQDNs`, and endpoint rules, owned by the custom resource
- [ ] Create the baseline deny-all egress policy for namespaces labelled for agents
- [ ] Detect whether the cluster has the Cilium CRDs; set the `NetworkEnforced` condition with a reason when it does not
- [ ] envtest coverage for create, update, and delete
- [ ] GitHub Actions: lint, unit tests, and a kind end-to-end job that installs Cilium and reruns the Stage 1 exfiltration test
- [ ] Checkpoint: tag v0.1.0 with green CI and a quick start in the README

### Stage 4: Controller v0.2, tools and agent-sandbox

Goal: per-tool rules, and coverage for agent-sandbox workloads.

- [ ] Turn `allowedTools` into L7 rules for in-cluster MCP servers; set `ToolFilterEnforced` accordingly
- [ ] Add a validating webhook for the custom resource, for example rejecting wildcard-only FQDNs
- [ ] Support `sandboxTemplateRef`: select the pods created from a SandboxTemplate, and watch Sandbox objects
- [ ] Add finalizers, Kubernetes events, and controller metrics
- [ ] End-to-end tests: an unlisted tool call is blocked; a directly created Sandbox in an agent namespace has no egress
- [ ] Checkpoint: tag v0.2.0

### Stage 5: Second backend and verification

Goal: prove it works, and say plainly where it doesn't.

- [ ] Put the policy generator behind a Go interface with two implementations: Cilium, and GKE Dataplane V2 using `FQDNNetworkPolicy`
- [ ] GKE session: create the cluster with [`terraform/gke-dataplane-v2`](terraform/gke-dataplane-v2/), enable FQDN network policy on it with `gcloud container clusters update`, run the suite, and destroy the cluster the same day
- [ ] Confirm whether GKE Dataplane V2 accepts Cilium L7 rules. If it does not, report `ToolFilterEnforced=False` with a clear reason and document the gateway fallback
- [ ] Attack suite: one scripted scenario per threat (unlisted domain, metadata address, cross-namespace Service, DNS exfiltration, unlisted tool, header and body mismatch), each with an expected result
- [ ] Audit: a small exporter that reads denied flows from Hubble and exposes a per-policy count
- [ ] Test matrix: container runtime (runc, gVisor) by platform (kind with Cilium, GKE Dataplane V2). One project reports that FQDN policy does not work with Kata guests; test it if you can, and record the result either way
- [ ] Checkpoint: publish the matrix as a table in the controller's README

### Stage 6: Publish

Goal: someone else can understand it, run it, and trust it.

- [ ] README with an architecture diagram and a five-minute quick start
- [ ] Threat model: what is protected, who the attacker is (a prompt-injected agent), which control stops what, and what is left uncovered
- [ ] A recorded demo of the attack suite, before and after the policy
- [ ] A write-up of the findings, especially anything that surprised you in the matrix
- [ ] Checkpoint: tag v0.3.0 and link it from this repo's README

## Upstream contributions

Run this alongside the stages. Reviews take a while, so start small and early.

- [ ] After Stage 1: read the agent-sandbox contributing guide, follow its issue tracker, and look for a documentation or example gap you hit in the labs
- [ ] After Stage 3: open a small pull request, for example a Cilium FQDN egress example next to the project's existing network policy examples
- [ ] After Stage 5: open a design discussion for a feature you needed, with your controller as the working reference

## Use cases

| Use case | What you build | Skill area | What it demonstrates |
| --- | --- | --- | --- |
| A prompt-injected agent tries to send data out | Default-deny egress with an FQDN allow-list, and Hubble evidence of the drop | Agent security, Cilium policy | A control that holds when the agent is compromised |
| An agent calls a tool it shouldn't | L7 rule on the `Mcp-Name` header for in-cluster MCP servers | MCP, L7 policy | Per-tool authorization below the application |
| "Which agent tried to reach what?" | Per-policy denied-flow counts from Hubble | Observability, audit | Evidence for a security review |
| A sandbox created without a policy | Baseline deny-all in agent namespaces | Secure defaults | Failing closed instead of open |
| Same policy, different cluster | Cilium and GKE Dataplane V2 backends with honest status conditions | Multi-cloud platform design | Knowing what each platform can enforce |
| Policy as an API | The `AgentEgressPolicy` custom resource and its controller | Go, controllers | Extending Kubernetes instead of hand-writing YAML |

## Risks and open questions

- **L7 header matching is unproven here.** Stage 1 tests it before the controller depends on it.
- **GKE Dataplane V2 limits.** Reports say it rejects Cilium L7 rules, and FQDN network policy has its own requirements. Verify both in the GKE session.
- **Scope.** Webhooks, envtest, and two backends are a lot. Cut features before cutting tests and CI.
- **Upstream timing.** A merge is not in your control. The controller and the write-up stand on their own.
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
8. What does your controller report when a cluster cannot enforce part of a policy, and why does that matter?
9. How does agent-sandbox manage network policy, and what happens to a Sandbox created directly?
10. A prompt-injected agent holds valid credentials for one MCP server. Which of your controls still limit the damage, and which do not?

## Progress

| Stage | Focus | Status |
| --- | --- | --- |
| 1 | Agent egress on Cilium | Not started |
| 2 | Go and controller fundamentals | Not started |
| 3 | Controller v0.1, FQDN egress | Not started |
| 4 | Controller v0.2, tools and agent-sandbox | Not started |
| 5 | Second backend and verification | Not started |
| 6 | Publish | Not started |

## Sources

- [MCP specification 2026-07-28: key changes](https://modelcontextprotocol.io/specification/2026-07-28/changelog)
- [MCP blog: The 2026-07-28 Specification](https://blog.modelcontextprotocol.io/posts/2026-07-28/)
- [agent-sandbox](https://github.com/kubernetes-sigs/agent-sandbox) and its [releases](https://github.com/kubernetes-sigs/agent-sandbox/releases)
- [agent-sandbox: network policy management](https://github.com/kubernetes-sigs/agent-sandbox/blob/main/examples/policy/network-policy-management/README.md)
- [Kubernetes blog: Running Agents on Kubernetes with Agent Sandbox](https://kubernetes.io/blog/2026/03/20/running-agents-on-kubernetes-with-agent-sandbox)
- [GKE: Control Pod egress traffic using FQDN network policies](https://docs.cloud.google.com/kubernetes-engine/docs/how-to/fqdn-network-policies)
- [O'Reilly Radar: Prompt Injection to Data Exfil in 3 Hops](https://www.oreilly.com/radar/prompt-injection-to-data-exfil-in-3-hops/)
- [Report on FQDN policy with Kata guests](https://github.com/sabbour/agentweaver/issues/2631)
- [Kubebuilder book](https://book.kubebuilder.io)
- [controller-runtime](https://github.com/kubernetes-sigs/controller-runtime)
- [A Tour of Go](https://go.dev/tour/)
