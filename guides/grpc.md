# gRPC study guide

Covers Protocol Buffers and gRPC in Go, to the level needed to write the Envoy external-authorization service in [BUILD_PLAN.md](../BUILD_PLAN.md) stage 6 and to explain how gRPC behaves on Kubernetes.

Study the key fundamentals, and make sure you can answer the questions at the end of the Study part, before you start the Labs part. Read [go.md](go.md) first.

## Study

### Key fundamentals

| # | Concept | What to understand |
| --- | --- | --- |
| 1 | gRPC versus REST | gRPC is contract-first, binary, and runs over HTTP/2 with generated clients and streaming; REST with JSON is readable, works in every browser and tool, and needs no code generation |
| 2 | Protocol Buffers | Messages are defined in a `.proto` file; each field has a type, a name, and a number; the number, not the name, goes on the wire |
| 3 | Compatibility rules | Never reuse or renumber a field; unknown fields are ignored; this is what lets client and server upgrade separately |
| 4 | Services and call types | A service is a set of methods; a call is unary, server streaming, client streaming, or bidirectional; the authorization service uses unary only |
| 5 | Generated code, server, and client | The compiler produces Go types for messages and an interface for the service; you implement the interface, register it with a server, and call it through a generated client with a context |
| 6 | Deadlines and cancellation | A deadline set by the caller travels with the call; the server sees it through the context and should stop work when it passes |
| 7 | Status codes | A call ends with a code such as OK, PermissionDenied, Unauthenticated, DeadlineExceeded, or Unavailable; return the right one |
| 8 | Metadata and interceptors | Metadata is key-value pairs sent with a call, like headers; interceptors wrap every call, for logging, metrics, and authentication |
| 9 | Transport and load balancing | Many calls share one long-lived HTTP/2 connection, so a connection-level load balancer sends them all to one backend; spreading calls needs an L7 proxy or client-side balancing; TLS and mutual TLS credentials |
| 10 | Health and debugging | The standard health-checking service, server reflection, and calling a service from the command line with `grpcurl` |
| 11 | Envoy's authorization API | Envoy calls a `Check` method with a request describing the HTTP call (source, destination, method, path, headers, and optionally the body); the service answers allow or deny; the Go types come from `go-control-plane` |

### Reading

1. Rows 2 and 3: the [Protocol Buffers language guide](https://protobuf.dev/programming-guides/proto3/).
2. Rows 4 and 5: the [gRPC Go quick start](https://grpc.io/docs/languages/go/quickstart/), then the [gRPC Go basics tutorial](https://grpc.io/docs/languages/go/basics/).
3. Rows 6 to 8 and 10: the guides section of the gRPC documentation for deadlines, status codes, metadata, interceptors, and health checking.
4. Row 9: [gRPC Load Balancing on Kubernetes without Tears](https://kubernetes.io/blog/2018/11/07/grpc-load-balancing-on-kubernetes-without-tears/).
5. Row 11: Envoy's [External Authorization filter](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/ext_authz_filter) page, and the authorization service types in [`go-control-plane`](https://github.com/envoyproxy/go-control-plane).

### Drills

Small programs that take one sitting each.

- [ ] Define a service with one unary method, generate the Go code, and write a server and a client
- [ ] Set a short deadline on the client, make the server slow, and observe the code the client receives
- [ ] Return `PermissionDenied` for one input, check for it on the client, and add an interceptor that logs every call with its duration and code
- [ ] Add the health service and call both it and your method with [`grpcurl`](https://github.com/fullstorydev/grpcurl)

### Pitfalls

- Changing a field number breaks every client that has not been regenerated. Add fields; don't renumber.
- A call without a deadline can wait forever. Set one on every client call.
- Returning a plain Go error produces the code Unknown. Return a status with the code you mean.
- A connection-level load balancer sends all calls on one HTTP/2 connection to one backend.
- An authorization service that is slow makes every request slow. Its latency is part of the request path.

### Questions you should be able to answer

After studying this guide, you should be able to answer the questions below. Answer each out loud, without notes, in about two minutes. The right-hand column is a checklist of what a strong answer covers, not a script.

| # | Question | A strong answer covers |
| --- | --- | --- |
| 1 | When would you choose gRPC over REST, and when not? | gRPC for service-to-service calls that need a strict contract, low overhead, streaming, and generated clients in several languages; REST for public APIs, browsers, and anything people debug with plain HTTP tools |
| 2 | How do you change a message without breaking clients? | Field numbers are the contract; add new fields with new numbers; never reuse or renumber; reserve the numbers of removed fields; old code ignores what it does not know |
| 3 | One of three gRPC replicas behind a Kubernetes Service takes all the traffic. Why, and how do you fix it? | Calls are multiplexed on one long-lived HTTP/2 connection and a Service balances connections, not requests; fix with an L7 proxy, mesh, or gateway, or a headless Service with client-side round robin; a maximum connection age helps but does not solve it |
| 4 | How do deadlines and cancellation work across a chain of services? | The caller sets a deadline; it travels with the call; the server's context is cancelled when it passes; pass that context to downstream calls so the whole chain stops; the caller sees DeadlineExceeded |
| 5 | How do you add authentication, logging, and metrics to every call? | Interceptors on server and client; credentials in metadata or mutual TLS at the transport; Unauthenticated when the caller is unknown and PermissionDenied when it is known but not allowed |
| 6 | How does Envoy's external authorization API work? | Envoy pauses the request and calls `Check` with its attributes; the answer is allow, optionally with header changes, or deny with a status and body; the call's latency and failure behaviour are part of every request |
| 7 | How do you debug a gRPC service running in a cluster? | Port-forward and call it with `grpcurl` using reflection; check the health service; read status codes instead of guessing; log every call from an interceptor; confirm every hop in between speaks HTTP/2 |

**Coding prompt to practise.** Sketch the `Check` handler for a service that allows a tool call only when the tool name is on an allow-list. Say which fields of the request you read, which status you return for a denial, and how you would test it without a network port.

### Go further

Optional. Come back to these after the labs.

- Streaming calls in depth
- Retries and service config
- Client-side load balancing driven by a control plane
- Exposing a gRPC service to REST clients
- In-process testing with an in-memory listener

## Labs

Do these once you can answer the questions above.

- [ ] [BUILD_PLAN.md](../BUILD_PLAN.md) stage 2: the gRPC basics task
- [ ] [BUILD_PLAN.md](../BUILD_PLAN.md) stage 6: the Envoy external-authorization service, after [envoy-gateway-api.md](envoy-gateway-api.md)

## Sources

- [Protocol Buffers language guide](https://protobuf.dev/programming-guides/proto3/)
- [gRPC Go quick start](https://grpc.io/docs/languages/go/quickstart/)
- [gRPC Go basics tutorial](https://grpc.io/docs/languages/go/basics/)
- [Kubernetes blog: gRPC Load Balancing on Kubernetes without Tears](https://kubernetes.io/blog/2018/11/07/grpc-load-balancing-on-kubernetes-without-tears/)
- [Envoy: External Authorization filter](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/ext_authz_filter)
- [go-control-plane](https://github.com/envoyproxy/go-control-plane)
- [grpcurl](https://github.com/fullstorydev/grpcurl)
