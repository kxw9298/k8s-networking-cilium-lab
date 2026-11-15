# gRPC study guide

Covers Protocol Buffers and gRPC in Go, to the level needed to write the Envoy external-authorization service in [BUILD_PLAN.md](../BUILD_PLAN.md) stage 6.

Finish the Study part and pass the readiness check before you start the Labs part. Read [go.md](go.md) first.

## Study

### Concepts, in order

| # | Concept | What to understand |
| --- | --- | --- |
| 1 | Protocol Buffers | Messages are defined in a `.proto` file; each field has a type, a name, and a number; the number, not the name, goes on the wire |
| 2 | Compatibility rules | Never reuse or renumber a field; unknown fields are ignored; this is what lets client and server upgrade separately |
| 3 | Services and methods | A service is a set of methods; each takes one message and returns one, or a stream of them |
| 4 | Call types | Unary, server streaming, client streaming, and bidirectional; the authorization service uses unary only |
| 5 | Code generation | The compiler produces Go types for messages and an interface for the service; you implement the interface on the server and call a generated client |
| 6 | Server and client in Go | Registering an implementation with a server, listening, and making a call from a client with a context |
| 7 | Deadlines and cancellation | A deadline set by the caller travels with the call; the server sees it through the context and should stop work when it passes |
| 8 | Status codes | A call ends with a code such as OK, PermissionDenied, Unauthenticated, DeadlineExceeded, or Unavailable; return the right one |
| 9 | Metadata | Key-value pairs sent with a call, the gRPC equivalent of headers |
| 10 | Interceptors | Functions that wrap every call, used for logging, metrics, and authentication |
| 11 | Transport | gRPC runs over HTTP/2, so a load balancer must understand HTTP/2 to spread calls; TLS and mutual TLS credentials |
| 12 | Health and debugging | The standard health-checking service, server reflection, and calling a service from the command line with `grpcurl` |
| 13 | Testing | Calling a server in-process without a real network port |
| 14 | Envoy's authorization API | Envoy calls a `Check` method with a request describing the HTTP call (source, destination, method, path, headers, and optionally the body); the service answers allow or deny; the Go types come from `go-control-plane` |

### Reading

1. Concepts 1 and 2: the [Protocol Buffers language guide](https://protobuf.dev/programming-guides/proto3/).
2. Concepts 3 to 6: the [gRPC Go quick start](https://grpc.io/docs/languages/go/quickstart/), then the [gRPC Go basics tutorial](https://grpc.io/docs/languages/go/basics/).
3. Concepts 7 to 13: the guides section of the gRPC documentation for deadlines, status codes, metadata, interceptors, and health checking.
4. Concept 14: Envoy's [External Authorization filter](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/ext_authz_filter) page, and the authorization service types in [`go-control-plane`](https://github.com/envoyproxy/go-control-plane).

### Drills

Small programs that take one sitting each.

- [ ] Define a service with one unary method, generate the Go code, and write a server and a client
- [ ] Set a short deadline on the client, make the server slow, and observe the code the client receives
- [ ] Return `PermissionDenied` for one input and check for it on the client
- [ ] Add an interceptor that logs every call with its duration and code
- [ ] Add the health service and call both it and your method with [`grpcurl`](https://github.com/fullstorydev/grpcurl)
- [ ] Read the `CheckRequest` and `CheckResponse` types and list the fields you would use to authorize an MCP tool call

### Pitfalls to know before you build

- Changing a field number breaks every client that has not been regenerated. Add fields; don't renumber.
- A call without a deadline can wait forever. Set one on every client call.
- Returning a plain Go error produces the code Unknown. Return a status with the code you mean.
- A connection-level load balancer sends all calls on one HTTP/2 connection to one backend.
- An authorization service that is slow makes every request slow. Its latency is part of the request path.

### Readiness check

Answer each out loud without notes.

1. Why does a field's number matter more than its name?
2. What are the four call types, and which one does a request-response check use?
3. How does a server learn that the caller has given up?
4. Which status code fits "the caller is known but not allowed", and which fits "the caller did not identify itself"?
5. How would you call a gRPC method from the command line?
6. What does Envoy send to an authorization service, and what can the service send back?

## Labs

Do these after the readiness check.

- [ ] [BUILD_PLAN.md](../BUILD_PLAN.md) stage 2: the gRPC basics task
- [ ] [BUILD_PLAN.md](../BUILD_PLAN.md) stage 6: the Envoy external-authorization service, after [envoy-gateway-api.md](envoy-gateway-api.md)

## Sources

- [Protocol Buffers language guide](https://protobuf.dev/programming-guides/proto3/)
- [gRPC Go quick start](https://grpc.io/docs/languages/go/quickstart/)
- [gRPC Go basics tutorial](https://grpc.io/docs/languages/go/basics/)
- [Envoy: External Authorization filter](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/ext_authz_filter)
- [go-control-plane](https://github.com/envoyproxy/go-control-plane)
- [grpcurl](https://github.com/fullstorydev/grpcurl)
