# MCP and agent security study guide

Covers how AI agents and the Model Context Protocol (MCP) work, how agents are authorized, what can go wrong, and which control answers which threat. It gives the security reasoning behind every stage of [BUILD_PLAN.md](../BUILD_PLAN.md).

Study the key fundamentals, and make sure you can answer the questions at the end of the Study part, before you start the Labs part. Read [oauth-oidc-jwt.md](oauth-oidc-jwt.md) and [kubernetes-security.md](kubernetes-security.md) first: rows 4 and 5 build on the first, rows 10 and 11 on the second.

## Study

### Key fundamentals

| # | Concept | What to understand |
| --- | --- | --- |
| 1 | Anatomy of an agent | A model, a set of tools it may call, some memory, and a loop that feeds tool results back to the model; the model decides the next action from text it was given. On Kubernetes the agent is a pod that calls a model endpoint and tool servers, often through a gateway |
| 2 | MCP | A client inside the agent talks to MCP servers, which offer tools, resources, and prompts; messages are JSON-RPC, such as `tools/list` and `tools/call`; a local transport over standard input and output, and Streamable HTTP for remote servers |
| 3 | The 2026-07-28 revision | A stateless protocol core, and the method and tool name carried in the `Mcp-Method` and `Mcp-Name` headers on Streamable HTTP so that gateways can route and authorize without parsing the body |
| 4 | MCP authorization | Built on OAuth 2.1: the MCP server is a resource server, publishes protected resource metadata, and accepts only tokens issued for itself; the client names the target server when it asks for a token; passing a received token on to another service is not allowed |
| 5 | Two identities | The agent's own workload identity, so every call can be attributed to one agent, and the user it acts for, carried as a scoped-down token obtained by token exchange instead of a broad shared credential |
| 6 | Prompt injection | Text the agent reads (a web page, a document, a tool result) contains instructions and the model may follow them; it cannot be fully prevented at the model, so the damage has to be limited elsewhere |
| 7 | Tool risks | Tool descriptions are untrusted input; a tool can change after it was approved; a tool can be broader than the task needs; an allowed tool can be used in a harmful way |
| 8 | Ways data leaves | Direct network egress, an allowed tool that sends data onward, DNS lookups, and the model endpoint itself |
| 9 | AI gateway | One controlled path between agents and models or tools: authentication, per-team quotas and cost limits, routing between models, logging, and content filters; it holds the provider keys so that agents never do |
| 10 | Isolation | A sandboxed runtime for agents that run generated code, no host access, no service account token unless needed, resource limits, and a default-deny network |
| 11 | Secrets | Short-lived credentials from workload identity instead of long-lived keys in the environment; injected at the gateway where possible; never written to logs |
| 12 | Audit and observability | For every call: which user, which agent, which tool, the decision, and a trace that links the prompt to the tool calls it caused; arguments are logged with secrets and personal data removed |
| 13 | Controls by layer | Identity, authorization, network, runtime isolation, secrets, human approval for high-impact actions, and audit. The OWASP Top 10 for Agentic Applications gives the shared vocabulary, including least agency: grant only the autonomy a task needs. A control counts when a test shows it blocking the attack |

### Reading

1. Rows 2 and 3: the MCP documentation at [modelcontextprotocol.io](https://modelcontextprotocol.io), then the [2026-07-28 key changes](https://modelcontextprotocol.io/specification/2026-07-28/changelog) and the [announcement](https://blog.modelcontextprotocol.io/posts/2026-07-28/).
2. Row 4: the [MCP authorization specification](https://modelcontextprotocol.io/specification/2026-07-28/basic/authorization).
3. Row 5: [RFC 8693, OAuth 2.0 Token Exchange](https://datatracker.ietf.org/doc/html/rfc8693), sections 1 and 2.
4. Rows 6 to 8 and 13: the [OWASP Top 10 for Agentic Applications](https://genai.owasp.org/resource/owasp-top-10-for-agentic-applications-for-2026/), and one worked attack: [Prompt Injection to Data Exfil in 3 Hops](https://www.oreilly.com/radar/prompt-injection-to-data-exfil-in-3-hops/).
5. Row 10: [Running Agents on Kubernetes with Agent Sandbox](https://kubernetes.io/blog/2026/03/20/running-agents-on-kubernetes-with-agent-sandbox).

### Drills

Paper exercises, before any lab.

- [ ] Take the example `tools/call` request from the 2026-07-28 announcement and name every header and every field in the body
- [ ] Draw the lab's agent, model endpoint, MCP server, and gateway, and mark every place where untrusted text enters
- [ ] Write a threat table for that drawing with four columns: asset, threat, control, and the test that would prove the control
- [ ] Decode a sample JSON Web Token and find the issuer, audience, expiry, and scopes; say what an MCP server must check
- [ ] Explain in two sentences why "the model will refuse" is not a security control

### Pitfalls

- Treating model behaviour as a boundary. Assume the agent can be made to try anything its permissions allow.
- One long-lived API key in a pod's environment, shared by every agent. It is the first thing an attacker asks the agent to send out.
- A token accepted by a server it was not issued for. Audience checks exist to stop this.
- Passing the caller's token on to another service instead of exchanging it.
- Wildcard egress "to make the agent work". Start from deny and add what is needed.
- Logs that record prompts and secrets in full.

### Questions you should be able to answer

After studying this guide, you should be able to answer the questions below. Answer each out loud, without notes, in about two minutes. The right-hand column is a checklist of what a strong answer covers, not a script.

| # | Question | A strong answer covers |
| --- | --- | --- |
| 1 | How do you defend against prompt injection? | It cannot be solved at the model, so assume the agent can be steered and limit what a steered agent can do: least-privilege tools, scoped short-lived credentials, an egress allow-list, isolation, human approval for high-impact actions, and monitoring; input and output filters are a layer, not a boundary |
| 2 | How should an agent authenticate, and act on behalf of a user? | Two identities: a workload identity for the agent and a delegated token for the user; exchange the user's token for one that is scoped down, bound to one audience, and short-lived; no shared long-lived keys; no token passthrough; every call attributable to a user and an agent |
| 3 | What is MCP, and how do you secure an MCP server? | A protocol that lets agents discover and call tools; JSON-RPC over Streamable HTTP for remote servers; the server is an OAuth 2.1 resource server that validates audience, issuer, expiry, and scope; an allow-list of servers and tools; tool descriptions treated as untrusted and re-approved when they change; a gateway in front for policy and logging |
| 4 | How can data leave a compromised agent, and what stops each path? | Network egress: default deny plus an allow-list by name; an allowed tool: tool-level authorization and argument checks; DNS: only the cluster resolver, with logging; the model endpoint: a gateway that logs and filters. Say which paths remain open |
| 5 | How do you isolate an agent that runs untrusted or generated code? | A sandboxed runtime with a stronger boundary than a plain container, no host mounts, no service account token, resource limits, a default-deny network, a short-lived environment per session, and separate nodes for the riskiest workloads |
| 6 | How do you handle secrets and API keys for agents? | The agent never holds the provider key; the gateway adds it; workload identity for short-lived credentials; one identity per agent so access can be scoped and revoked; rotation; secrets kept out of prompts and logs |
| 7 | What do you log and monitor for agents? | Per call: user, agent, tool, decision, token usage and cost, and trace IDs that link a prompt to its tool calls; alerts on denied calls, new egress destinations, and spikes; redaction and retention rules, because prompts contain personal data |
| 8 | What does an AI gateway do, and why put one in front of models and tools? | One place for authentication, quotas and cost control, model routing and fallback, logging, and content filtering; it keeps provider keys away from agents; the trade-off is a new critical component on the request path |

**Design prompt to practise.** Design a platform for running AI agents for several teams on Kubernetes. Cover the tenancy boundary, identity for agents and users, the path to models and tools, the network policy, runtime isolation, secrets, and audit. Then name three attacks you would run to prove it.

### Go further

Optional. Come back to these after the labs.

- Agent-to-agent protocols and the risks of multi-agent systems
- Memory poisoning and the rest of the OWASP list
- Workload identity standards such as SPIFFE
- Red-team testing and evaluations for agents
- Governance frameworks for AI risk

## Labs

Do these once you can answer the questions above.

- [ ] [BUILD_PLAN.md](../BUILD_PLAN.md) stage 1: block egress and unlisted tool calls by hand
- [ ] [BUILD_PLAN.md](../BUILD_PLAN.md) stage 3: run agents under agent-sandbox and kagent
- [ ] [BUILD_PLAN.md](../BUILD_PLAN.md) stage 6: authorize tool calls at the gateway
- [ ] [BUILD_PLAN.md](../BUILD_PLAN.md) stage 8: turn the threat table into the attack suite

## Sources

- [Model Context Protocol](https://modelcontextprotocol.io)
- [MCP specification 2026-07-28: key changes](https://modelcontextprotocol.io/specification/2026-07-28/changelog)
- [MCP blog: The 2026-07-28 Specification](https://blog.modelcontextprotocol.io/posts/2026-07-28/)
- [MCP authorization specification](https://modelcontextprotocol.io/specification/2026-07-28/basic/authorization)
- [RFC 8693: OAuth 2.0 Token Exchange](https://datatracker.ietf.org/doc/html/rfc8693)
- [OWASP Top 10 for Agentic Applications](https://genai.owasp.org/resource/owasp-top-10-for-agentic-applications-for-2026/)
- [O'Reilly Radar: Prompt Injection to Data Exfil in 3 Hops](https://www.oreilly.com/radar/prompt-injection-to-data-exfil-in-3-hops/)
- [Kubernetes blog: Running Agents on Kubernetes with Agent Sandbox](https://kubernetes.io/blog/2026/03/20/running-agents-on-kubernetes-with-agent-sandbox)
