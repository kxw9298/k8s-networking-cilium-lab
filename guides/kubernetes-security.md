# Kubernetes and container security study guide

Covers what isolates a container, how Kubernetes decides who may do what, and the controls that keep a workload contained. It is the basis for isolating agent workloads in [BUILD_PLAN.md](../BUILD_PLAN.md).

Study the key fundamentals, and make sure you can answer the questions at the end of the Study part, before you start the Labs part. Read [kubernetes-networking.md](kubernetes-networking.md) first.

## Study

### Key fundamentals

| # | Concept | What to understand |
| --- | --- | --- |
| 1 | What a container is | A process with namespaces (what it can see: processes, network, mounts, users), cgroups (what it can use), and reduced privileges; it shares the host's kernel, so a kernel bug can be a way out |
| 2 | Privileges | Root in a container is root on the host unless user namespaces are used; capabilities split root's power into pieces you can drop; seccomp filters system calls; AppArmor or SELinux confines files and networking. Privileged mode, host namespaces, host path mounts, and the runtime socket are each a path to the node |
| 3 | Pod Security Standards | Three levels: privileged, baseline, and restricted; Pod Security Admission enforces a level per namespace through labels, with enforce, audit, and warn modes |
| 4 | Sandboxed runtimes | gVisor puts a user-space kernel between the workload and the host; Kata Containers runs each pod in a small virtual machine; a RuntimeClass selects one; the price is performance and compatibility |
| 5 | Authentication and RBAC | Users authenticate with certificates or OIDC, workloads with service accounts; Roles and ClusterRoles list verbs on resources, bindings grant them; RBAC only adds, there is no deny; `kubectl auth can-i` answers "can this identity do that" |
| 6 | Service accounts | Every pod runs as one; its token is projected into the pod, short-lived, bound to an audience, and rotated by the kubelet; turn off mounting when the pod never calls the API; one service account per workload |
| 7 | Admission control | After authentication and authorization and before storage, mutating then validating; Pod Security Admission, CEL admission policies, webhooks, and policy engines such as Kyverno and Gatekeeper all sit here |
| 8 | Secrets | A Secret is base64-encoded, not encrypted; encryption at rest has to be turned on; anyone who can read Secrets in a namespace, or create pods in it, can get them; external secret stores and workload identity reduce what is stored at all |
| 9 | Network isolation | Every pod can reach every other pod until a policy says otherwise; default-deny per namespace, then allow; block the cloud metadata address; control egress as well as ingress |
| 10 | Multi-tenancy in layers | The namespace is the unit: RBAC, quotas and limits, network policy, and a Pod Security level on each; separate nodes for untrusted workloads; a namespace is not a hard boundary, so the riskiest tenants get a sandboxed runtime or their own cluster |
| 11 | Supply chain | Know what you run: images from registries you trust, pinned by digest, scanned, signed, and verified at admission; minimal base images |
| 12 | Audit and detection | The API audit log records who did what; runtime detection watches for behaviour a workload should never show, such as a shell or an unexpected connection; decide in advance what raises an alert |

### Reading

1. Rows 1 and 2: `man 7 namespaces`, `man 7 cgroups`, and `man 7 capabilities`, then Kubernetes documentation on [configuring a security context](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/).
2. Row 3: [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/).
3. Row 4: [Runtime Class](https://kubernetes.io/docs/concepts/containers/runtime-class/), the [gVisor](https://gvisor.dev/docs/) documentation's overview, and [Running Agents on Kubernetes with Agent Sandbox](https://kubernetes.io/blog/2026/03/20/running-agents-on-kubernetes-with-agent-sandbox).
4. Rows 5 and 6: [Using RBAC Authorization](https://kubernetes.io/docs/reference/access-authn-authz/rbac/) and [Service accounts](https://kubernetes.io/docs/concepts/security/service-accounts/).
5. Row 7: [Admission control](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/) and [Validating Admission Policy](https://kubernetes.io/docs/reference/access-authn-authz/validating-admission-policy/).
6. Rows 8 and 10: [Good practices for Kubernetes Secrets](https://kubernetes.io/docs/concepts/security/secrets-good-practices/) and [Multi-tenancy](https://kubernetes.io/docs/concepts/security/multi-tenancy/).

### Drills

Short checks that need only `kubectl` and a kind cluster.

- [ ] Find a container's process on the node and list its namespaces and its cgroup
- [ ] Run `kubectl auth can-i --list` as a namespace's default service account; then write a Role and RoleBinding that let it read ConfigMaps in that namespace and nothing else
- [ ] Label a namespace to enforce the restricted level, try to create a privileged pod, and fix the pod spec until it is admitted
- [ ] Write a security context from memory that passes the restricted level: non-root, no privilege escalation, all capabilities dropped, the default seccomp profile; add a read-only root filesystem on top
- [ ] From inside a pod, read the mounted service account token, decode it, and say what an attacker could do with it given that account's permissions

### Pitfalls

- Containers share the host's kernel. A container is not a boundary against a kernel exploit.
- RBAC has no deny rule. Removing access means removing a binding.
- Permission to create pods in a namespace is permission to run as any service account in it and to mount any Secret in it.
- `list` on Secrets returns their contents.
- A webhook that fails open stops enforcing when it is down; one that fails closed can block the whole cluster when it is down. Scope it narrowly and exclude system namespaces.
- The service account token is mounted unless you turn it off.
- A namespace with no Pod Security label enforces nothing.

### Questions you should be able to answer

After studying this guide, you should be able to answer the questions below. Answer each out loud, without notes, in about two minutes. The right-hand column is a checklist of what a strong answer covers, not a script.

| # | Question | A strong answer covers |
| --- | --- | --- |
| 1 | What isolates a container from the host and from other containers? | Namespaces for what it sees, cgroups for what it uses, capabilities and seccomp and a mandatory access control profile for what it may do; all enforced by one shared kernel, which is the weak point |
| 2 | How do you harden a pod spec? | Run as non-root, no privilege escalation, drop all capabilities, default seccomp profile, read-only root filesystem, no host namespaces or host paths, resource limits, no service account token unless needed; enforce it with the restricted level instead of trusting each manifest |
| 3 | How does Kubernetes authenticate and authorize a request, and how does RBAC go wrong? | Identity from a certificate, an OIDC token, or a service account token; RBAC matches verbs and resources through bindings; it goes wrong through wildcards, cluster-wide bindings where a namespace would do, and indirect paths such as creating pods, reading Secrets, or impersonation |
| 4 | A pod is compromised. What can the attacker reach, and what limits it? | The service account token and whatever it allows; Secrets mounted or in the environment; every pod and the metadata address on the network; the node, through the kernel or a host mount. Limits: no token or a minimal role, network policy, the restricted level, a sandboxed runtime, short-lived credentials, and detection |
| 5 | How do you enforce rules on what can be deployed? | Admission: Pod Security Admission for pod hardening, CEL admission policies for simple rules, a policy engine for richer ones; start in audit or warn mode, then enforce; decide how each policy behaves when its component is down; keep exemptions few and reviewed |
| 6 | How do you manage secrets in a cluster? | Encrypt at rest with a key held outside the cluster; narrow who can read them; prefer an external store or workload identity so little is stored; mount as files instead of environment variables; rotate; keep them out of images, logs, and Git |
| 7 | How do you isolate tenants in one cluster, and when is a namespace not enough? | Namespace plus RBAC, quotas, network policy, and a Pod Security level; separate nodes for untrusted work; a namespace does not protect against a kernel exploit or a cluster-scoped mistake, so hostile or highly sensitive tenants get a sandboxed runtime or separate clusters |
| 8 | When do you need a sandboxed runtime, and what does it cost? | When the workload runs untrusted or generated code; gVisor intercepts system calls in user space, Kata uses a virtual machine boundary; costs are start-up time, performance, and features that behave differently, so test the network and storage paths you depend on |

**Scenario to practise.** A team wants to run agents that execute code written by a model. List the pod-level and namespace-level controls you would require before allowing it, and say which attack each one stops.

### Go further

Optional. Come back to these after the labs.

- User namespaces for pods
- Mutating admission policies written in CEL
- Verifying image signatures at admission
- Runtime detection tools built on eBPF
- Hardening the control plane and the nodes
- Virtual clusters
- Confidential computing

## Labs

Do these once you can answer the questions above.

- [ ] [BUILD_PLAN.md](../BUILD_PLAN.md) stage 1: the exfiltration tests to the cloud metadata address and to a Service in another namespace
- [ ] [BUILD_PLAN.md](../BUILD_PLAN.md) stage 3: agent-sandbox, and the extension that runs a sandbox under the gVisor RuntimeClass
- [ ] [BUILD_PLAN.md](../BUILD_PLAN.md) stage 4, extension: the practice operator, whose controller should run with only the permissions it needs
- [ ] [BUILD_PLAN.md](../BUILD_PLAN.md) stage 8: the container runtime rows of the test matrix

## Sources

- [Kubernetes: Configure a security context for a pod or container](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/)
- [Kubernetes: Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
- [Kubernetes: Runtime Class](https://kubernetes.io/docs/concepts/containers/runtime-class/)
- [Kubernetes: Using RBAC Authorization](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
- [Kubernetes: Service accounts](https://kubernetes.io/docs/concepts/security/service-accounts/)
- [Kubernetes: Admission control](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/)
- [Kubernetes: Validating Admission Policy](https://kubernetes.io/docs/reference/access-authn-authz/validating-admission-policy/)
- [Kubernetes: Good practices for Kubernetes Secrets](https://kubernetes.io/docs/concepts/security/secrets-good-practices/)
- [Kubernetes: Multi-tenancy](https://kubernetes.io/docs/concepts/security/multi-tenancy/)
- [gVisor documentation](https://gvisor.dev/docs/)
- [Kubernetes blog: Running Agents on Kubernetes with Agent Sandbox](https://kubernetes.io/blog/2026/03/20/running-agents-on-kubernetes-with-agent-sandbox)
