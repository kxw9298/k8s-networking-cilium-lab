# Kubernetes controllers and operators study guide

Covers how the Kubernetes API and controllers work, and how an operator is built with controller-runtime and Kubebuilder. It prepares for stages 3, 4, and 7 of [BUILD_PLAN.md](../BUILD_PLAN.md).

Study the key fundamentals, and make sure you can answer the questions at the end of the Study part, before you start the Labs part. Read [go.md](go.md) first.

## Study

### Key fundamentals

| # | Concept | What to understand |
| --- | --- | --- |
| 1 | The path of a request | `kubectl apply` reaches the API server, which authenticates, authorizes, runs mutating admission, validates the schema, runs validating admission, and stores the object in etcd; everything after that is controllers, the scheduler, and kubelets reacting through watches |
| 2 | The control loop | A controller compares desired state (`spec`) with observed state and acts to close the gap, again and again; it reacts to the current state, not to a history of events |
| 3 | API objects | Group, version, and kind; namespaced versus cluster-scoped; `metadata`, `spec`, and `status`; `resourceVersion`, `generation`, and `deletionTimestamp` |
| 4 | Custom resources and operators | A CustomResourceDefinition adds a new kind with a validated schema; an operator is a custom resource plus a controller that carries the knowledge of how to run something |
| 5 | Informers and the work queue | An informer lists and watches objects and keeps a local cache; reads come from the cache, writes go to the API server; changes put an object's key on a queue, duplicate keys collapse, and failures are retried with backoff |
| 6 | The reconcile function | Given a key: fetch the object, handle "not found", handle deletion, compute what should exist, create or update it, write status, and return; running it twice must be harmless |
| 7 | controller-runtime | The manager, controllers, and reconcilers; declaring what to watch (`For`, `Owns`, `Watches`); predicates that filter events; asking to be called again later |
| 8 | Owner references and finalizers | A child names its owner, so deleting the owner garbage-collects the child, and a change to the child triggers the owner's reconcile when the controller declares that kind with `Owns`; a finalizer blocks deletion until the controller has cleaned up something outside the cluster |
| 9 | Status and conditions | Status reports what the controller observed; conditions have a type, a status, a reason, and a message; `observedGeneration` says which version of the spec the status describes |
| 10 | Conflicts | Updates use optimistic concurrency on `resourceVersion`; a stale write is rejected and retried; update, patch, and server-side apply differ in how they merge |
| 11 | Testing | Unit tests for pure functions; envtest runs a real API server and etcd with no kubelet and no built-in controllers; end-to-end tests on kind |
| 12 | Admission | Mutating webhooks run first and may change an object; validating webhooks run after and can only accept or reject; a failure policy decides what happens when a webhook is down; validation rules in the schema and CEL admission policies cover many cases without a webhook |
| 13 | Production readiness | Leader election so only one replica acts, a service account with only the permissions needed, metrics, health probes, structured logs, and a plan for upgrading a custom resource's versions |

### Reading

1. Rows 1 to 4: Kubernetes documentation on [controllers](https://kubernetes.io/docs/concepts/architecture/controller/), [custom resources](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/), and the [operator pattern](https://kubernetes.io/docs/concepts/extend-kubernetes/operator/).
2. Row 5: the README and code of [`sample-controller`](https://github.com/kubernetes/sample-controller), which shows informers and a work queue without a framework.
3. Rows 6, 7, and 13: the [Kubebuilder book](https://book.kubebuilder.io), read through the CronJob tutorial once before typing any of it.
4. Row 8: Kubernetes documentation on [owners and dependents](https://kubernetes.io/docs/concepts/overview/working-with-objects/owners-dependents/) and [finalizers](https://kubernetes.io/docs/concepts/overview/working-with-objects/finalizers/).
5. Row 9: the status and conditions sections of the [Kubernetes API conventions](https://github.com/kubernetes/community/blob/master/contributors/devel/sig-architecture/api-conventions.md).
6. Row 11: the Kubebuilder book's page on [envtest](https://book.kubebuilder.io/reference/envtest).
7. Row 12: Kubernetes documentation on [dynamic admission control](https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/). [kubernetes-security.md](kubernetes-security.md) covers admission as a security control.

### Drills

Short checks that need only `kubectl` and a kind cluster.

- [ ] Write a CustomResourceDefinition by hand with a schema that requires one field; create a valid object, then try an invalid one and read the error
- [ ] Run `kubectl get pods --watch`, delete a pod owned by a Deployment, and say which controller did what
- [ ] Add a finalizer to a ConfigMap, delete it, and observe that it stays until the finalizer is removed
- [ ] Edit an object twice from two terminals so that one write is rejected, and read the conflict error
- [ ] On paper, write the reconcile steps for "a custom resource that should own exactly one ConfigMap"

### Pitfalls

- Reading from the cache straight after a write can return the old object. Don't assume your own write is visible yet.
- Changing the object on every reconcile triggers another reconcile, without end. Only write when something differs.
- Status has its own update call. A normal update does not change it.
- Reconcile must not rely on having seen every event. Events can be merged or missed; the current state is what counts.
- A finalizer that is never removed leaves the object stuck in deletion.
- An owner must be in the same namespace as its child, or be cluster-scoped.
- Because envtest runs no built-in controllers, pods never start and owner-based garbage collection does not happen there.

### Questions you should be able to answer

After studying this guide, you should be able to answer the questions below. Answer each out loud, without notes, in about two minutes. The right-hand column is a checklist of what a strong answer covers, not a script.

| # | Question | A strong answer covers |
| --- | --- | --- |
| 1 | What happens when you run `kubectl apply` on a Deployment? | API server: authentication, authorization, mutating admission, schema validation, validating admission, etcd; the Deployment controller creates a ReplicaSet; the ReplicaSet controller creates pods; the scheduler picks a node for each; the kubelet starts containers through the runtime and CNI; each component watches and writes status back |
| 2 | Why are controllers level-triggered, and why does that matter? | They act on current state, not on a stream of events; a missed or merged event does no harm because the next reconcile sees the same gap; restarts and retries are safe for the same reason |
| 3 | How do informers and the work queue work, and why not query the API server each time? | List then watch into a local cache; shared between controllers; reads are cheap and do not load the API server; the queue holds keys, collapses duplicates, limits the rate, and retries with backoff; the cache can be slightly stale |
| 4 | Walk through a reconcile function. What makes it idempotent? | Fetch; not found means nothing to do; deletion means clean up and remove the finalizer; compute desired children; create or update only on a difference; write status; requeue if waiting. It compares and converges instead of assuming what happened before |
| 5 | When do you use an owner reference, and when a finalizer? | Owner reference for children inside the cluster that should be garbage-collected with the parent; finalizer when something outside the cluster, or in another namespace, must be cleaned up first |
| 6 | Two writers update the same object at once. What happens? | Each write carries a `resourceVersion`; the second is rejected with a conflict; re-read and retry, or use a patch or server-side apply so that each writer owns only its own fields; never retry with stale data |
| 7 | What makes an operator production-ready? | Leader election, least-privilege permissions, metrics and alerts on reconcile errors and queue depth, health probes, conditions that tell a user what is wrong, tests at three levels, and safe upgrades of the custom resource's versions |
| 8 | When would you write an operator instead of using Helm or GitOps? | Helm and GitOps apply manifests and stop; an operator keeps acting after install, for example failover, backup, scaling on a custom signal, or managing something outside the cluster; the cost is code to maintain and wide permissions, so prefer an existing operator when one fits |
| 9 | What is the difference between a mutating and a validating webhook, and what can go wrong with them? | Mutating runs first and can change the object, validating runs last and only accepts or rejects; every matching API request waits for the webhook, so latency and timeouts matter; failing open stops enforcement, failing closed can block the cluster, so scope it narrowly and exclude system namespaces; prefer schema rules or a CEL admission policy when they are enough |

**Design prompt to practise.** Design a custom resource and controller that gives each agent workload an egress allow-list. Say what goes in `spec` and in `status`, which objects the controller owns, how it reacts when someone edits one of those objects by hand, and what happens on deletion.

### Go further

Optional. Come back to these after the labs.

- Writing and testing an admission webhook
- Serving several versions of a custom resource, with conversion
- Server-side apply and field ownership in depth
- The client-go internals under an informer
- Packaging and distributing an operator

## Labs

Do these once you can answer the questions above.

- [ ] [BUILD_PLAN.md](../BUILD_PLAN.md) stage 2: the client-go informer program
- [ ] [BUILD_PLAN.md](../BUILD_PLAN.md) stage 3: run agent-sandbox and kagent, and read agent-sandbox's controller
- [ ] [BUILD_PLAN.md](../BUILD_PLAN.md) stage 4: type out the Kubebuilder CronJob tutorial; the practice operator is the extension
- [ ] [BUILD_PLAN.md](../BUILD_PLAN.md) stage 7: contribute upstream

## Sources

- [Kubernetes: Controllers](https://kubernetes.io/docs/concepts/architecture/controller/)
- [Kubernetes: Custom resources](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/)
- [Kubernetes: Operator pattern](https://kubernetes.io/docs/concepts/extend-kubernetes/operator/)
- [Kubernetes: Owners and dependents](https://kubernetes.io/docs/concepts/overview/working-with-objects/owners-dependents/)
- [Kubernetes: Finalizers](https://kubernetes.io/docs/concepts/overview/working-with-objects/finalizers/)
- [Kubernetes API conventions](https://github.com/kubernetes/community/blob/master/contributors/devel/sig-architecture/api-conventions.md)
- [Kubernetes: Dynamic admission control](https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/)
- [Kubebuilder book](https://book.kubebuilder.io)
- [Kubebuilder book: envtest](https://book.kubebuilder.io/reference/envtest)
- [sample-controller](https://github.com/kubernetes/sample-controller)
- [controller-runtime](https://github.com/kubernetes-sigs/controller-runtime)
