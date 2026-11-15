# MCP and agent security study guide

Covers how AI agents and the Model Context Protocol (MCP) work, how agents are authorized, what can go wrong, and which control answers which threat. It gives the security reasoning behind every stage of [BUILD_PLAN.md](../BUILD_PLAN.md).

Finish the Study part and pass the readiness check before you start the Labs part.

## Study

### Concepts, in order

| # | Concept | What to understand |
| --- | --- | --- |
| 1 | Anatomy of an agent | A model, a set of tools it may call, some memory, and a loop that feeds tool results back to the model; the model decides the next action from text it was given |
| 2 | Agents on Kubernetes | The agent runs in a pod; it calls a model endpoint, usually outside the cluster, and tool servers, inside or outside; a gateway may sit in between |
| 3 | MCP roles and primitives | A client inside the agent talks to MCP servers; servers offer tools, resources, and prompts |
| 4 | MCP messages and transports | JSON-RPC messages such as `tools/list` and `tools/call`; a local transport over standard input and output, and Streamable HTTP for remote servers |
| 5 | The 2026-07-28 revision | A stateless protocol core, and the method and tool name carried in the `Mcp-Method` and `Mcp-Name` headers on Streamable HTTP so that gateways can route and authorize without parsing the body |
| 6 | MCP authorization | Built on OAuth 2.1: the MCP server is a resource server, publishes protected resource metadata, and accepts only tokens issued for itself; the client names the target server when it asks for a token |
| 7 | Acting on behalf of a user | The agent should carry a token that is scoped down and tied to the user it acts for, obtained by token exchange, instead of a broad shared credential |
| 8 | The agent's own identity | A workload identity for the agent itself, separate from the user's, so that every call can be attributed to one agent |
| 9 | Prompt injection | Text the agent reads (a web page, a document, a tool result) contains instructions; the model may follow them; it cannot be fully prevented at the model, so the damage has to be limited elsewhere |
| 10 | Tool risks | Tool descriptions are untrusted input; a tool can change after it was approved; a tool can be broader than the task needs; an allowed tool can be used in a harmful way |
| 11 | Ways data leaves | Direct network egress, an allowed tool that sends data onward, DNS lookups, and the model endpoint itself |
| 12 | A shared vocabulary | The OWASP Top 10 for Agentic Applications names ten risks, from agent goal hijack to rogue agents, and the principle of least agency: grant only the autonomy a task needs |
| 13 | Controls by layer | Identity (who is calling, for whom), authorization (which tools), network (which hosts), runtime isolation (what the process can touch), secrets (short-lived, not in the environment), human approval for high-impact actions, and audit |
| 14 | Evidence | A control counts when a test shows it blocking the attack and a log shows who tried what |

### Reading

1. Concepts 3 to 5: the MCP documentation at [modelcontextprotocol.io](https://modelcontextprotocol.io), then the [2026-07-28 key changes](https://modelcontextprotocol.io/specification/2026-07-28/changelog) and the [announcement](https://blog.modelcontextprotocol.io/posts/2026-07-28/).
2. Concept 6: the [MCP authorization specification](https://modelcontextprotocol.io/specification/2026-07-28/basic/authorization).
3. Concept 7: [RFC 8693, OAuth 2.0 Token Exchange](https://datatracker.ietf.org/doc/html/rfc8693), sections 1 and 2.
4. Concepts 9 to 12: the [OWASP Top 10 for Agentic Applications](https://genai.owasp.org/resource/owasp-top-10-for-agentic-applications-for-2026/).
5. Concepts 9 and 11, as one worked attack: [Prompt Injection to Data Exfil in 3 Hops](https://www.oreilly.com/radar/prompt-injection-to-data-exfil-in-3-hops/).
6. Concept 13, for runtime isolation: [Running Agents on Kubernetes with Agent Sandbox](https://kubernetes.io/blog/2026/03/20/running-agents-on-kubernetes-with-agent-sandbox).

### Drills

Paper exercises, before any lab.

- [ ] Take the example `tools/call` request from the 2026-07-28 announcement and name every header and every field in the body
- [ ] Draw the lab's agent, model endpoint, MCP server, and gateway, and mark every place where untrusted text enters
- [ ] Write a threat table for that drawing with four columns: asset, threat, control, and the test that would prove the control
- [ ] For each of the ten OWASP agentic risks, name the layer from concept 13 that addresses it
- [ ] Decode a sample JSON Web Token and find the issuer, audience, expiry, and scopes; say what an MCP server must check
- [ ] Explain in two sentences why "the model will refuse" is not a security control

### Pitfalls to know before you build

- Treating model behaviour as a boundary. Assume the agent can be made to try anything its permissions allow.
- One long-lived API key in a pod's environment, shared by every agent. It is the first thing an attacker asks the agent to send out.
- A token accepted by a server it was not issued for. Audience checks exist to stop this.
- Passing the caller's token on to another service instead of exchanging it.
- Wildcard egress "to make the agent work". Start from deny and add what is needed.
- Logs that record prompts and secrets in full.

### Readiness check

Answer each out loud without notes.

1. What are the parts of an agent, and at which point can injected text change what it does?
2. What do `tools/list` and `tools/call` do, and what travels in the headers since 2026-07-28?
3. In MCP authorization, what must the server check about a token?
4. Why exchange a token instead of passing it through?
5. Name four ways data can leave a compromised agent, and one control for each.
6. What does least agency mean in practice for a tool list?
7. Which controls still hold when the agent is fully compromised, and which do not?

## Labs

Do these after the readiness check.

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
