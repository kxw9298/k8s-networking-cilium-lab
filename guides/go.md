# Go study guide

Covers the Go you need to read operator code and to write a CNI plugin, an eBPF loader, and a small network service. It assumes you already program in another language.

Finish the Study part and pass the readiness check before you start the Labs part.

## Study

### Concepts, in order

| # | Concept | What to understand |
| --- | --- | --- |
| 1 | Toolchain and modules | `go mod init`, `go build`, `go run`, `go test`, `go vet`, `gofmt`; what `go.mod` and `go.sum` record; packages, and that a capitalised name is exported |
| 2 | Types and zero values | Basic types, structs, arrays, slices, and maps; every type has a zero value; `:=` versus `var`; constants |
| 3 | Slices and maps in depth | A slice is a view (pointer, length, capacity) over an array; `append` may or may not copy; nil versus empty; map iteration order is random; the two-value lookup |
| 4 | Functions and methods | Multiple return values, closures, `defer` and when its arguments are evaluated; value receivers versus pointer receivers |
| 5 | Pointers | When to pass a pointer and when a value; nil pointers; no pointer arithmetic |
| 6 | Interfaces | Satisfied implicitly; keep them small; an interface value holds a type and a value, so an interface holding a nil pointer is not nil; type assertions and type switches |
| 7 | Errors | Errors are values that you return and check; wrap with `%w`; test with `errors.Is` and `errors.As`; panic is for bugs, not for expected failures |
| 8 | Generics | Type parameters and constraints, at the level needed to read library code that uses them |
| 9 | Concurrency | Goroutines, channels, `select`, `sync.WaitGroup`, `sync.Mutex`; what a data race is and how the race detector finds one; how goroutines leak |
| 10 | Context | Cancellation and deadlines passed down a call chain; `ctx` is the first parameter; every Kubernetes client call and every gRPC call takes one |
| 11 | Testing | The `testing` package, table-driven tests, subtests, test helpers, `httptest`, coverage |
| 12 | Encoding and struct tags | `encoding/json`, tags such as `json:"name,omitempty"`, embedded structs; this is how Kubernetes API types map to YAML |
| 13 | Standard library | `net/http`, `io`, `os`, `time`, `flag`, and structured logging with `log/slog` |
| 14 | Project layout and delivery | `cmd/` and `internal/`, a Makefile, a linter, and building a small static binary into a container image |

### Reading

1. Concepts 1 to 6: [A Tour of Go](https://go.dev/tour/), doing every exercise.
2. Concepts 2 to 8, as a reference while you write: [Go by Example](https://gobyexample.com).
3. Concepts 7, 9, and 11, with practice built in: [Learn Go with Tests](https://quii.gitbook.io/learn-go-with-tests).
4. Concept 10: [Go Concurrency Patterns: Context](https://go.dev/blog/context).
5. Style and idiom, once the basics are in place: [Effective Go](https://go.dev/doc/effective_go).

### Drills

Small programs that take one sitting each. They are part of studying, not labs.

- [ ] A command-line word counter that reads a file, with table-driven tests for the counting function
- [ ] The same program returning wrapped errors for a missing file and a bad flag, with a test that checks each with `errors.Is`
- [ ] A function that takes an `io.Reader`, tested with `strings.NewReader` instead of a real file
- [ ] An HTTP server with one JSON endpoint, tested with `httptest`, that shuts down cleanly when its context is cancelled
- [ ] A concurrent URL checker with a fixed number of workers and a per-request timeout, passing `go test -race`
- [ ] Decode a Kubernetes manifest from YAML into a struct you wrote, using struct tags

### Pitfalls to know before you build

- An interface holding a nil pointer does not equal nil. Return a plain `nil` error, not a nil pointer of an error type.
- Writing to a nil map panics. Appending to a nil slice is fine.
- Two slices can share one underlying array, so a change through one can show up in the other.
- `:=` inside a block creates a new variable. It is easy to shadow `err` and lose an error.
- A goroutine blocked on a channel nobody reads from never exits.
- Ignoring a returned error compiles. Check every one.
- A `defer` inside a loop runs when the function returns, not at the end of each iteration.

### Readiness check

Answer each out loud without notes.

1. What is the difference between a nil slice and an empty slice, and when does `append` copy?
2. When do you choose a pointer receiver?
3. Why can an interface value be non-nil when the pointer inside it is nil?
4. How do you add context to an error and still let a caller test for the original?
5. What does `context.Context` carry, and what should a function do when it is cancelled?
6. What is a data race, and how do you find one?
7. Why are table-driven tests the usual shape for Go tests?
8. How does a struct tag change the way a field is encoded?

## Labs

Do these after the readiness check.

- [ ] [STUDY_PLAN.md](../STUDY_PLAN.md), "CNI internals": rewrite the bash CNI plugin in Go
- [ ] [BUILD_PLAN.md](../BUILD_PLAN.md) stage 2: tests for the CNI plugin, and the client-go informer program
- [ ] Continue with [grpc.md](grpc.md) before the gRPC task in stage 2

## Sources

- [A Tour of Go](https://go.dev/tour/)
- [Go by Example](https://gobyexample.com)
- [Learn Go with Tests](https://quii.gitbook.io/learn-go-with-tests)
- [Go Concurrency Patterns: Context](https://go.dev/blog/context)
- [Effective Go](https://go.dev/doc/effective_go)
