# Envoy and Gateway API study guide

Covers how Envoy processes a request, how the Gateway API describes routing, and how external authorization fits in. It prepares for stages 5 and 6 of [BUILD_PLAN.md](../BUILD_PLAN.md).

Finish the Study part and pass the readiness check before you start the Labs part. Read [kubernetes-networking.md](kubernetes-networking.md) and [grpc.md](grpc.md) first.

## Study

### Concepts, in order

| # | Concept | What to understand |
| --- | --- | --- |
| 1 | L4 and L7 proxies | An L4 proxy forwards connections; an L7 proxy reads each request and can route, change, or reject it |
| 2 | Envoy's request path | A listener accepts the connection; a filter chain processes it; the HTTP connection manager runs HTTP filters in order; the router picks a cluster; the cluster picks an endpoint |
| 3 | Downstream and upstream | Downstream is the client side, upstream is the backend side; settings and statistics are named this way |
| 4 | Configuration | Static configuration in a file, or dynamic configuration pushed by a control plane; a gateway controller translates Kubernetes resources into Envoy configuration |
| 5 | HTTP filters | Each filter does one job (JWT validation, external authorization, rate limiting, routing); order matters, and the router is last |
| 6 | External authorization | The filter pauses the request and calls a service with the request's attributes; the service answers allow or deny; a denied request gets a 403 unless the service says otherwise |
| 7 | Authorization settings | The timeout for the call; whether a failed call allows or denies the request (deny is the default); whether the request body is sent, and how much; which routes skip the check |
| 8 | Identity at the gateway | Where the caller's identity comes from: a client certificate, a validated token, or a header set by a trusted hop; why client-supplied identity headers must be removed |
| 9 | Gateway API resources | GatewayClass names an implementation; Gateway defines listeners; HTTPRoute matches on path, headers, and method and points to backends; ReferenceGrant allows cross-namespace references |
| 10 | Policy attachment | Features beyond routing, including external authorization, are attached with implementation-specific resources, so the YAML differs between gateways |
| 11 | Timeouts, retries, and streaming | Request and idle timeouts; which requests are safe to retry; long-lived streaming responses need different timeouts from short requests |
| 12 | Observability | Access logs and their response flags, statistics, tracing with context passed through the proxy, and the admin interface for dumping live configuration |
| 13 | Failure modes | A slow or unavailable authorizer, failing open versus failing closed, large bodies, and what the client sees in each case |
| 14 | MCP at the gateway | MCP over Streamable HTTP is a POST with JSON-RPC in the body; since the 2026-07-28 specification the method and tool name are also in the `Mcp-Method` and `Mcp-Name` headers, so a gateway can route and authorize without parsing the body |
| 15 | Where gateways sit with Cilium | Cilium uses Envoy for its own L7 policy and can act as a Gateway API implementation; a separate gateway in front of MCP servers is another option |

### Reading

1. Concepts 1 to 5: Envoy's [Life of a Request](https://www.envoyproxy.io/docs/envoy/latest/intro/life_of_a_request).
2. Concepts 6 and 7: Envoy's [External Authorization filter](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/ext_authz_filter) page.
3. Concepts 9 and 10: the [Gateway API](https://gateway-api.sigs.k8s.io) concepts and HTTPRoute pages.
4. Concept 10, one concrete example: Envoy Gateway's [External Authorization](https://gateway.envoyproxy.io/docs/tasks/security/ext-auth) task, which attaches the check with a `SecurityPolicy`.
5. Concept 14: the [MCP 2026-07-28 key changes](https://modelcontextprotocol.io/specification/2026-07-28/changelog).

### Drills

Short checks before any lab.

- [ ] Draw the path of one request through Envoy, naming listener, filter chain, HTTP filters, router, cluster, and endpoint
- [ ] From the external authorization page, write down the default timeout, the default behaviour when the call fails, and how to send the body
- [ ] Write a Gateway and an HTTPRoute from memory that send `POST /mcp` to one Service and everything else nowhere
- [ ] Decide, with a reason, whether an agent gateway should fail open or fail closed when its authorizer is down
- [ ] List the headers an authorizer needs for an MCP tool call, and which of them the client could forge

### Pitfalls to know before you build

- Filter order is behaviour. Authorization placed after a filter that already acted on the request is too late.
- A short authorization timeout turns a slow authorizer into denied or allowed requests, depending on the failure setting. Choose on purpose.
- The body is not sent to the authorizer unless you ask for it, and only up to a size limit.
- An identity header is only trustworthy if the gateway strips whatever the client sent and sets it itself.
- Policy resources are not portable between Gateway API implementations.
- Streaming responses can be cut off by idle timeouts tuned for short requests.

### Readiness check

Answer each out loud without notes.

1. Name the stages a request passes through in Envoy, in order.
2. What does the external authorization filter send, and what can come back?
3. What happens to requests when the authorizer is down, with the default setting and with the opposite one?
4. What is the difference between a Gateway and an HTTPRoute, and who owns each?
5. Why does external authorization need implementation-specific configuration?
6. How can a gateway authorize an MCP tool call without reading the body, and when is that safe?
7. Where would you look to find out why Envoy returned a 403?

## Labs

Do these after the readiness check.

- [ ] [STUDY_PLAN.md](../STUDY_PLAN.md), "Cilium advanced": the Gateway API task
- [ ] [BUILD_PLAN.md](../BUILD_PLAN.md) stage 5: find which Envoy handled an agent's request and read its configuration
- [ ] [BUILD_PLAN.md](../BUILD_PLAN.md) stage 6: the external-authorization service, then its extensions

## Sources

- [Envoy: Life of a Request](https://www.envoyproxy.io/docs/envoy/latest/intro/life_of_a_request)
- [Envoy: External Authorization filter](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/ext_authz_filter)
- [Gateway API](https://gateway-api.sigs.k8s.io)
- [Envoy Gateway: External Authorization](https://gateway.envoyproxy.io/docs/tasks/security/ext-auth)
- [agentgateway](https://agentgateway.dev)
- [MCP specification 2026-07-28: key changes](https://modelcontextprotocol.io/specification/2026-07-28/changelog)
