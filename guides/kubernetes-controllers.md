# Kubernetes controllers and operators study guide

Covers how the Kubernetes API and controllers work, and how an operator is built with controller-runtime and Kubebuilder. It prepares for stages 3, 4, and 7 of [BUILD_PLAN.md](../BUILD_PLAN.md).

Finish the Study part and pass the readiness check before you start the Labs part. Read [go.md](go.md) first.

## Study

### Concepts, in order

| # | Concept | What to understand |
| --- | --- | --- |
| 1 | The control loop | A controller compares desired state (`spec`) with observed state and acts to close the gap, again and again; it reacts to the current state, not to a history of events |
| 2 | API objects | Group, version, and kind; namespaced versus cluster-scoped; `metadata`, `spec`, and `status`; `resourceVersion`, `generation`, and `deletionTimestamp` |
| 3 | Custom resources | A CustomResourceDefinition adds a new kind to the API; its schema validates objects; versions, defaulting, and the status subresource |
| 4 | Operators | A custom resource plus a controller that carries the knowledge of how to run something |
| 5 | Watches and informers | A controller lists and watches objects through an informer, which keeps a local cache; reads come from the cache, writes go to the API server |
| 6 | The work queue | Changes put an object's key on a queue; duplicate keys collapse; a worker takes a key and reconciles that object; failures are retried with backoff |
| 7 | The reconcile function | Given a key: fetch the object, handle "not found", handle deletion, compute what should exist, create or update it, write status, and return; running it twice must be harmless |
| 8 | controller-runtime | The manager, controllers, and reconcilers; declaring what to watch (`For`, `Owns`, `Watches`); predicates that filter events; asking to be called again later |
| 9 | Owner references | A child object names its owner; deleting the owner garbage-collects the children; a change to a child triggers the owner's reconcile |
| 10 | Finalizers | A marker that blocks deletion until the controller has cleaned up something outside the cluster, then removes the marker |
| 11 | Status and conditions | Status reports what the controller observed; conditions have a type, a status, a reason, and a message; `observedGeneration` says which version of the spec the status describes |
| 12 | Conflicts | Updates use optimistic concurrency; a stale write is rejected and retried; update, patch, and server-side apply differ in how they merge |
| 13 | Access control | A controller runs under a service account with only the permissions it needs; Kubebuilder generates the roles from markers in the code |
| 14 | Admission | Validating and mutating webhooks check or change objects on the way in; validation rules in the schema cover many cases without a webhook |
| 15 | Testing | Unit tests for pure functions; envtest runs a real API server and etcd with no kubelet and no built-in controllers; end-to-end tests on kind |
| 16 | Running it | Leader election, metrics, health probes, structured logs, and how a custom resource's versions are upgraded |

### Reading

1. Concepts 1 to 4: Kubernetes documentation on [controllers](https://kubernetes.io/docs/concepts/architecture/controller/), [custom resources](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/), and the [operator pattern](https://kubernetes.io/docs/concepts/extend-kubernetes/operator/).
2. Concepts 5 and 6: the README and code of [`sample-controller`](https://github.com/kubernetes/sample-controller), which shows informers and a work queue without a framework.
3. Concepts 7, 8, and 13: the [Kubebuilder book](https://book.kubebuilder.io), read through the CronJob tutorial once before typing any of it.
4. Concepts 9 and 10: Kubernetes documentation on [owners and dependents](https://kubernetes.io/docs/concepts/overview/working-with-objects/owners-dependents/) and [finalizers](https://kubernetes.io/docs/concepts/overview/working-with-objects/finalizers/).
5. Concept 11: the status and conditions sections of the [Kubernetes API conventions](https://github.com/kubernetes/community/blob/master/contributors/devel/sig-architecture/api-conventions.md).
6. Concept 15: the Kubebuilder book's page on [envtest](https://book.kubebuilder.io/reference/envtest).

### Drills

Short checks that need only `kubectl` and a kind cluster.

- [ ] Write a CustomResourceDefinition by hand with a schema that requires one field; create a valid object, then try an invalid one and read the error
- [ ] Run `kubectl get pods --watch`, delete a pod owned by a Deployment, and say which controller did what
- [ ] Find the owner references on a pod and follow them up to the Deployment
- [ ] Add a finalizer to a ConfigMap, delete it, and observe that it stays until the finalizer is removed
- [ ] Edit an object twice from two terminals so that one write is rejected, and read the conflict error
- [ ] On paper, write the reconcile steps for "a custom resource that should own exactly one ConfigMap"

### Pitfalls to know before you build

- Reading from the cache straight after a write can return the old object. Don't assume your own write is visible yet.
- Changing the object on every reconcile triggers another reconcile, without end. Only write when something differs.
- Status has its own update call. A normal update does not change it.
- Reconcile must not rely on having seen every event. Events can be merged or missed; the current state is what counts.
- A finalizer that is never removed leaves the object stuck in deletion.
- Long, blocking work inside reconcile stalls the queue. Return and ask to be called again.
- Because envtest runs no built-in controllers, pods never start and owner-based garbage collection does not happen there.

### Readiness check

Answer each out loud without notes.

1. Why is a controller described as level-triggered, and why does that make it robust?
2. What does an informer cache, and why read from it instead of the API server?
3. Why does the work queue hold keys and not events?
4. List the steps of a typical reconcile function in order.
5. When do you use an owner reference, and when a finalizer?
6. What is `observedGeneration` for?
7. What happens when two writers update the same object at once?
8. What can envtest test, and what can it not?

## Labs

Do these after the readiness check.

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
- [Kubebuilder book](https://book.kubebuilder.io)
- [Kubebuilder book: envtest](https://book.kubebuilder.io/reference/envtest)
- [sample-controller](https://github.com/kubernetes/sample-controller)
- [controller-runtime](https://github.com/kubernetes-sigs/controller-runtime)
