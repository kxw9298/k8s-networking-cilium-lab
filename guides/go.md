# Go study guide

Covers the Go you need to read operator code and to write a CNI plugin, an eBPF loader, and a small network service. It assumes you already program in another language.

Study the key fundamentals, and make sure you can answer the questions at the end of the Study part, before you start the Labs part.

## Study

### Key fundamentals

| # | Concept | What to understand |
| --- | --- | --- |
| 1 | Toolchain and modules | `go mod init`, `go build`, `go test`, `go vet`, `gofmt`; what `go.mod` and `go.sum` record; packages, and that a capitalised name is exported |
| 2 | Types and zero values | Basic types, structs, arrays, slices, and maps; every type has a zero value; `:=` versus `var` |
| 3 | Slices and maps | A slice is a view (pointer, length, capacity) over an array; `append` may or may not copy; nil versus empty; map iteration order is random; the two-value lookup |
| 4 | Functions, methods, and pointers | Multiple return values and closures; `defer` runs at function return, last in first out, with arguments evaluated when it is declared; value receivers versus pointer receivers |
| 5 | Interfaces | Satisfied implicitly; keep them small; an interface value holds a type and a value, so an interface holding a nil pointer is not nil |
| 6 | Errors | Errors are values that you return and check; wrap with `%w`; test with `errors.Is` and `errors.As`; `panic` is for bugs, and `recover` only works inside a deferred function |
| 7 | Goroutines and channels | A goroutine is a cheap thread managed by the runtime; an unbuffered channel hands over a value when both sides are ready, a buffered one blocks only when full; sending on a closed channel panics, receiving from a closed and drained one returns the zero value at once, and a nil channel blocks forever; `select` waits on several |
| 8 | Sharing and races | `sync.WaitGroup` to wait, `sync.Mutex` to protect shared state; a data race is unsynchronised access where at least one side writes; `go test -race` finds them; a goroutine with no way to exit is a leak |
| 9 | Context | Cancellation and deadlines passed down a call chain; `ctx` is the first parameter; every Kubernetes client call and every gRPC call takes one |
| 10 | Testing | The `testing` package, table-driven tests, subtests, and `httptest` |
| 11 | JSON and struct tags | `encoding/json` and tags such as `json:"name,omitempty"`; this is how Kubernetes API types map to YAML |
| 12 | Building a service | `net/http`, `io.Reader` and `io.Writer`, structured logging with `log/slog`, a `cmd/` and `internal/` layout, and a small static binary in a container image |

### Reading

1. Rows 1 to 5: [A Tour of Go](https://go.dev/tour/), doing every exercise, and [Go Slices: usage and internals](https://go.dev/blog/slices-intro) for row 3.
2. Rows 6, 7, 8, and 10, with practice built in: [Learn Go with Tests](https://quii.gitbook.io/learn-go-with-tests).
3. Row 9: [Go Concurrency Patterns: Context](https://go.dev/blog/context).
4. As a reference while you write: [Go by Example](https://gobyexample.com), and [Effective Go](https://go.dev/doc/effective_go) for idiom.

### Drills

Small programs that take one sitting each. They are part of studying, not labs.

- [ ] A command-line word counter that reads a file, with table-driven tests for the counting function
- [ ] The same program returning wrapped errors for a missing file and a bad flag, with a test that checks each with `errors.Is`
- [ ] An HTTP server with one JSON endpoint, tested with `httptest`, that shuts down cleanly when its context is cancelled
- [ ] A concurrent URL checker with a fixed number of workers and a per-request timeout, passing `go test -race`
- [ ] Decode a Kubernetes manifest from YAML into a struct you wrote, using struct tags

### Pitfalls

- An interface holding a nil pointer does not equal nil. Return a plain `nil` error, not a nil pointer of an error type.
- Writing to a nil map panics. Appending to a nil slice is fine.
- Two slices can share one underlying array, so a change through one can show up in the other.
- `:=` inside a block creates a new variable. It is easy to shadow `err` and lose an error.
- A goroutine blocked on a channel nobody reads from never exits.
- A `defer` inside a loop runs when the function returns, not at the end of each iteration.

### Questions you should be able to answer

After studying this guide, you should be able to answer the questions below. Answer each out loud, without notes, in about two minutes. The right-hand column is a checklist of what a strong answer covers, not a script.

| # | Question | A strong answer covers |
| --- | --- | --- |
| 1 | What is the difference between an array and a slice, and what happens on `append`? | An array has a fixed size that is part of its type; a slice is a pointer, a length, and a capacity over an array; `append` writes in place while capacity allows and otherwise allocates and copies, so two slices can share memory or silently stop sharing it |
| 2 | How do interfaces work, and what is the nil-interface trap? | Implicit satisfaction; small interfaces defined where they are used; an interface value is a type plus a value, so one holding a nil pointer is not equal to nil; return a plain `nil` error |
| 3 | When do you use a pointer receiver? | When the method changes the receiver, when the struct is large or holds a mutex, and for consistency across a type's methods; it also decides whether a value or only a pointer satisfies an interface |
| 4 | How does Go handle errors, and when is `panic` right? | Errors are returned values; add context with `%w`; callers test with `errors.Is` and `errors.As`; `panic` is for programmer bugs; `recover` in a deferred function at a boundary such as a request handler |
| 5 | What is a goroutine, and how do you coordinate several? | Cheap, scheduled by the runtime onto OS threads; channels to pass data, `WaitGroup` to wait, `Mutex` for shared state, context to cancel; pick one owner for each piece of data |
| 6 | Explain how channels behave: buffered, unbuffered, closed, and nil. | Unbuffered synchronises sender and receiver; buffered blocks only when full or empty; send on closed panics; receive on closed returns the zero value and `false`; nil blocks forever; the sender closes |
| 7 | What is `context.Context` for? | Cancellation, deadlines, and request-scoped values down a call chain; first parameter; long work watches `ctx.Done()`; always call the cancel function; not a bag for optional arguments |
| 8 | How do you find and prevent data races and goroutine leaks? | A race is concurrent access with a write and no synchronisation; the race detector in tests and CI; a mutex or a single owning goroutine; every goroutine needs a way out (context or a closed channel); a goroutine profile shows leaks |

**Coding prompt to practise.** Write a worker pool: a fixed number of workers read URLs from a channel, fetch each with a per-request timeout, and send results back; the program stops cleanly when its context is cancelled. Then say how you would test it.

### Go further

Optional. Come back to these after the labs.

- Generics, to the level needed to read library code that uses type parameters
- The scheduler and garbage collector at a high level
- Profiling with `pprof`
- `errgroup` and other patterns from `golang.org/x/sync`
- A linter and a Makefile for a real project

## Labs

Do these once you can answer the questions above.

- [ ] [STUDY_PLAN.md](../STUDY_PLAN.md), "CNI internals": rewrite the bash CNI plugin in Go
- [ ] [BUILD_PLAN.md](../BUILD_PLAN.md) stage 2: tests for the CNI plugin, and the client-go informer program
- [ ] Continue with [grpc.md](grpc.md) before the gRPC task in stage 2

## Sources

- [A Tour of Go](https://go.dev/tour/)
- [Go Slices: usage and internals](https://go.dev/blog/slices-intro)
- [Go by Example](https://gobyexample.com)
- [Learn Go with Tests](https://quii.gitbook.io/learn-go-with-tests)
- [Go Concurrency Patterns: Context](https://go.dev/blog/context)
- [Effective Go](https://go.dev/doc/effective_go)
