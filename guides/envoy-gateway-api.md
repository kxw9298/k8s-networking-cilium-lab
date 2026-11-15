# Envoy and Gateway API study guide

Covers the HTTP basics a proxy works with, how Envoy processes a request, how the Gateway API describes routing, what a service mesh adds, and how external authorization fits in. It prepares for stages 5 and 6 of [BUILD_PLAN.md](../BUILD_PLAN.md).

Study the key fundamentals, and make sure you can answer the questions at the end of the Study part, before you start the Labs part. Read [kubernetes-networking.md](kubernetes-networking.md), [tls-mtls.md](tls-mtls.md), and [grpc.md](grpc.md) first.

## Study

### Key fundamentals

| # | Concept | What to understand |
| --- | --- | --- |
| 1 | HTTP basics | A request is a method, a path, headers, and an optional body; a response is a status code, headers, and a body; 4xx means the client's request was refused or wrong, 5xx means the server or a proxy failed; GET, PUT, and DELETE are safe to repeat, POST is not; HTTP/1.1 carries one request at a time on a connection, HTTP/2 multiplexes many streams over one connection, HTTP/3 does the same over QUIC |
| 2 | L4 and L7 proxies | An L4 proxy forwards connections; an L7 proxy reads each request and can route, change, or reject it |
| 3 | Envoy's request path | A listener accepts the connection; a filter chain processes it; the HTTP connection manager runs HTTP filters in order; the router picks a cluster; the cluster picks an endpoint. Downstream is the client side, upstream is the backend side |
| 4 | Configuration | Static configuration in a file, or dynamic configuration pushed by a control plane; a gateway controller translates Kubernetes resources into Envoy configuration |
| 5 | HTTP filters | Each filter does one job (JWT validation, external authorization, rate limiting, routing); order matters, and the router is last |
| 6 | Ingress and Gateway API | Ingress is one resource with annotations for anything beyond basic routing, and its API is frozen; Gateway API has GatewayClass (which implementation), Gateway (listeners, owned by the platform team), HTTPRoute (matching and backends, owned by the application team), and ReferenceGrant (cross-namespace references) |
| 7 | Policy attachment | Features beyond routing, including external authorization, are attached with implementation-specific resources, so that YAML differs between gateways |
| 8 | Service mesh | Proxies between every pair of services give workload identity with mutual TLS, traffic policy, and telemetry without changing application code; a sidecar mesh runs a proxy in every pod, a sidecarless mesh runs a shared L4 layer per node and adds an L7 proxy only where needed |
| 9 | External authorization | The filter pauses the request and calls a service with the request's attributes; the service answers allow or deny; a denied request gets a 403 unless the service says otherwise; settings cover the timeout, whether a failed call allows or denies (deny is the default), and whether the body is sent |
| 10 | Identity at the gateway | Where the caller's identity comes from: a client certificate, a validated token, or a header set by a trusted hop; why client-supplied identity headers must be removed |
| 11 | Resilience | Request and idle timeouts; retries only for requests that are safe to repeat; circuit breaking and outlier detection to stop sending to a failing backend; rate limiting; long-lived streaming responses need different timeouts from short requests |
| 12 | Observability | Access logs and their response flags, statistics, tracing with context passed through the proxy, and the admin interface for dumping live configuration |
| 13 | MCP at the gateway | MCP over Streamable HTTP is a POST with JSON-RPC in the body; since the 2026-07-28 specification the method and tool name are also in the `Mcp-Method` and `Mcp-Name` headers, so a gateway can route and authorize without parsing the body |

### Reading

1. Row 1: [RFC 9110, HTTP Semantics](https://www.rfc-editor.org/rfc/rfc9110.html), sections 9 (methods) and 15 (status codes). Skim; it is a reference.
2. Rows 2 to 5: Envoy's [Life of a Request](https://www.envoyproxy.io/docs/envoy/latest/intro/life_of_a_request).
3. Rows 6 and 7: the [Gateway API](https://gateway-api.sigs.k8s.io) concepts and HTTPRoute pages, and Kubernetes documentation on [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/).
4. Row 8: Istio's [ambient mode overview](https://istio.io/latest/docs/ambient/overview/), which also explains how it differs from sidecars.
5. Row 9: Envoy's [External Authorization filter](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/ext_authz_filter) page, and Envoy Gateway's [External Authorization](https://gateway.envoyproxy.io/docs/tasks/security/ext-auth) task, which attaches the check with a `SecurityPolicy`.
6. Row 13: the [MCP 2026-07-28 key changes](https://modelcontextprotocol.io/specification/2026-07-28/changelog).

### Drills

Short checks before any lab.

- [ ] Draw the path of one request through Envoy, naming listener, filter chain, HTTP filters, router, cluster, and endpoint
- [ ] From the external authorization page, write down the default timeout, the default behaviour when the call fails, and how to send the body
- [ ] Write a Gateway and an HTTPRoute from memory that send `POST /mcp` to one Service and everything else nowhere
- [ ] Decide, with a reason, whether an agent gateway should fail open or fail closed when its authorizer is down

### Pitfalls

- Filter order is behaviour. Authorization placed after a filter that already acted on the request is too late.
- A short authorization timeout turns a slow authorizer into denied or allowed requests, depending on the failure setting. Choose on purpose.
- The body is not sent to the authorizer unless you ask for it, and only up to a size limit.
- An identity header is only trustworthy if the gateway strips whatever the client sent and sets it itself.
- Retries multiply load on a backend that is already struggling.
- Policy resources are not portable between Gateway API implementations.

### Questions you should be able to answer

After studying this guide, you should be able to answer the questions below. Answer each out loud, without notes, in about two minutes. The right-hand column is a checklist of what a strong answer covers, not a script.

| # | Question | A strong answer covers |
| --- | --- | --- |
| 1 | What changes between HTTP/1.1 and HTTP/2, and why does a proxy care? | One request at a time per connection versus many multiplexed streams; binary framing and header compression; connections live much longer, so balancing has to happen per request at L7; a proxy often speaks one version to the client and another to the backend; HTTP/3 moves the same model onto QUIC |
| 2 | What is the difference between L4 and L7 load balancing, and when do you need L7? | L4 balances connections and knows addresses and ports; L7 balances requests and sees paths, headers, and methods; L7 is needed for routing by path or host, per-request balancing of HTTP/2 and gRPC, retries, and request-level authorization |
| 3 | Walk a request through Envoy. | Listener, filter chain, HTTP connection manager, HTTP filters in order, router, cluster, endpoint; where TLS ends; where a request can be rejected before it reaches a backend |
| 4 | How does Gateway API differ from Ingress, and why move? | Role split between platform and application teams; routing features in the spec instead of controller annotations; cross-namespace routing with explicit grants; more protocols; the Ingress API is frozen and its most used community controller has been retired |
| 5 | What is a service mesh, what does it give you, and when is it not worth it? | Mutual TLS with workload identity, traffic policy, and uniform telemetry without application changes; sidecar versus sidecarless trade-offs in cost and isolation; not worth it for a few services or when the network layer and a gateway already cover the need |
| 6 | How does external authorization work, and should it fail open or closed? | The filter calls a service for each request and applies its answer; the service's latency is added to every request; fail closed for security decisions and plan for the authorizer's availability; fail open only where availability outranks the control, and say who accepted that |
| 7 | How does a gateway establish who the caller is? | Mutual TLS, a validated token (issuer, audience, expiry, signature), or a header from a trusted hop; strip identity headers that arrive from the client; pass identity upstream in a form the backend can verify |
| 8 | How do you set timeouts, retries, and circuit breaking without making an outage worse? | A timeout per attempt and for the whole request; retry only idempotent requests, with backoff and a budget; circuit breaking limits what is sent to a struggling backend; outlier detection removes bad hosts; retries at several layers multiply |
| 9 | A client gets a 403 or a 503 from the gateway. How do you find the cause? | Access log response flags say whether the proxy or the backend produced it; then the authorizer's logs for a 403, and upstream health, timeouts, and routes for a 503; dump the live configuration to confirm what is running; follow the trace |

**Design prompt to practise.** Design the gateway that sits in front of several MCP servers. Say how a tool call is identified, how the caller is authenticated, where the allow or deny decision is made, what is logged, and what happens when the authorizer is down.

### Go further

Optional. Come back to these after the labs.

- Writing or reading an Envoy control plane
- Extending Envoy with external processing or WebAssembly
- A rate limiting service
- Routes for gRPC and TLS, and Gateway API for model inference traffic
- [agentgateway](https://agentgateway.dev), a gateway built for MCP and agent-to-agent traffic
- Cilium as a Gateway API implementation, and how its own L7 policy uses Envoy

## Labs

Do these once you can answer the questions above.

- [ ] [STUDY_PLAN.md](../STUDY_PLAN.md), "Cilium advanced": the Gateway API task
- [ ] [BUILD_PLAN.md](../BUILD_PLAN.md) stage 5: find which Envoy handled an agent's request and read its configuration
- [ ] [BUILD_PLAN.md](../BUILD_PLAN.md) stage 6: the external-authorization service, then its extensions

## Sources

- [RFC 9110: HTTP Semantics](https://www.rfc-editor.org/rfc/rfc9110.html)
- [Envoy: Life of a Request](https://www.envoyproxy.io/docs/envoy/latest/intro/life_of_a_request)
- [Envoy: External Authorization filter](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/ext_authz_filter)
- [Gateway API](https://gateway-api.sigs.k8s.io)
- [Kubernetes: Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)
- [Istio: Ambient mode overview](https://istio.io/latest/docs/ambient/overview/)
- [Envoy Gateway: External Authorization](https://gateway.envoyproxy.io/docs/tasks/security/ext-auth)
- [agentgateway](https://agentgateway.dev)
- [MCP specification 2026-07-28: key changes](https://modelcontextprotocol.io/specification/2026-07-28/changelog)
