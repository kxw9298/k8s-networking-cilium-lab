# TLS, PKI, and mutual TLS study guide

Covers how TLS protects a connection, how certificates establish identity, and how mutual TLS gives workloads an identity. It is the basis for every question about traffic security at a gateway or in a mesh.

Study the key fundamentals, and make sure you can answer the questions at the end of the Study part, before you start the Labs part. Read [kubernetes-networking.md](kubernetes-networking.md) first.

## Study

### Key fundamentals

| # | Concept | What to understand |
| --- | --- | --- |
| 1 | What TLS provides | Confidentiality, integrity, and proof of who the server is, and of who the client is when it also presents a certificate; it says nothing about what the peer is allowed to do |
| 2 | Keys and certificates | Asymmetric keys prove identity and agree on a secret; symmetric keys encrypt the data; a certificate binds a public key to a name and is signed by an issuer |
| 3 | The TLS 1.3 handshake | The client sends its supported versions and cipher suites, a key share, the server name (SNI), and the protocols it speaks (ALPN); the server answers with its key share, then its certificate and a signature that proves it holds the private key; both derive the same keys; one round trip, and ephemeral keys give forward secrecy |
| 4 | Chains and validation | A leaf certificate chains through intermediates to a root the client already trusts; the client checks each signature, that the name it dialled is in the Subject Alternative Names, the validity dates, and the permitted usage; revocation is mostly handled by short lifetimes |
| 5 | Public and private PKI | A public CA for names on the internet; a private CA for internal services, where you also distribute the trust bundle; the root key stays offline and intermediates do the signing |
| 6 | SNI and ALPN | SNI names the host in the clear at the start of the handshake, so a server or proxy can pick a certificate or a backend without decrypting; ALPN selects HTTP/1.1 or HTTP/2 |
| 7 | Where TLS ends | Terminate at the gateway, terminate and re-encrypt to the backend, or pass through untouched; each choice decides whether the gateway can see and act on the HTTP request |
| 8 | Mutual TLS | The server also asks for a client certificate, so both sides are proven; the caller's identity comes from its certificate; it authenticates, it does not authorize |
| 9 | Workload identity | A SPIFFE ID is a URI carried in the certificate's Subject Alternative Name; a mesh or SPIRE issues short-lived certificates to workloads and rotates them automatically; in Kubernetes the identity usually comes from the namespace and service account |
| 10 | Certificates in Kubernetes | TLS Secrets hold a certificate and key; cert-manager issues and renews them; the cluster has its own PKI for the API server, kubelets, and etcd; admission webhooks need a certificate the API server trusts |
| 11 | Rotation and expiry | Expiry is the most common TLS outage; automate renewal, monitor expiry dates, and reload without a restart; replacing a CA means trusting old and new together for a while |
| 12 | Encryption layers compared | Node-to-node encryption (WireGuard, IPsec) protects the wire and identifies nodes; mutual TLS identifies workloads; TLS done by the application is opaque to L7 policy in the network |
| 13 | Debugging | `openssl s_client` with `-servername` shows the chain a server presents; `openssl x509 -text` shows names and dates; the four errors to recognise are unknown authority, name mismatch, expired, and handshake failure |

### Reading

1. Rows 1 to 4: [The Illustrated TLS 1.3 Connection](https://tls13.xargs.org/), which walks through one real handshake. Use [RFC 8446](https://datatracker.ietf.org/doc/html/rfc8446), section 2, as the reference.
2. Rows 6 and 7: the Gateway API [TLS configuration](https://gateway-api.sigs.k8s.io/guides/tls/) guide.
3. Rows 8 and 9: [SPIFFE concepts](https://spiffe.io/docs/latest/spiffe-about/spiffe-concepts/).
4. Row 10: Kubernetes documentation on [PKI certificates and requirements](https://kubernetes.io/docs/setup/best-practices/certificates/), and the [cert-manager](https://cert-manager.io/docs/) documentation's concepts section.

### Drills

Short checks that need only `openssl`, `curl`, and one terminal.

- [ ] Run `openssl s_client -connect <host>:443 -servername <host>` against any public site and read the chain, the Subject Alternative Names, the validity dates, and the negotiated version and cipher suite
- [ ] Create a root CA, sign a server certificate with a Subject Alternative Name, serve it, and connect with `curl --cacert`; then break it three ways (wrong name, expired, unknown CA) and read each error
- [ ] Require a client certificate on that server; connect with one and without one
- [ ] On paper, for termination, re-encryption, and passthrough, mark where the plaintext exists and what the gateway can route on
- [ ] Decode the certificate in a Kubernetes TLS Secret and find its issuer and expiry

### Pitfalls

- The name is checked against the Subject Alternative Names. Modern clients ignore the Common Name.
- Turning off verification (`curl -k`, `InsecureSkipVerify`) leaves encryption without authentication.
- A server that omits its intermediate certificate works in some browsers and fails in `curl` and Go.
- Mutual TLS proves who is calling, not that they may. Authorization is a separate step.
- With passthrough the gateway sees no paths or headers, so it cannot apply HTTP rules.
- A proxy that terminates TLS hides the client certificate from the backend. If it forwards the identity in a header, the backend must accept that header only from the proxy.
- An unmonitored certificate is an outage with a known date.

### Questions you should be able to answer

After studying this guide, you should be able to answer the questions below. Answer each out loud, without notes, in about two minutes. The right-hand column is a checklist of what a strong answer covers, not a script.

| # | Question | A strong answer covers |
| --- | --- | --- |
| 1 | What does TLS guarantee, and what does it not? | Confidentiality, integrity, and server authentication, plus client authentication with mutual TLS; not authorization, not the security of either endpoint, and not metadata such as addresses, the server name, and sizes |
| 2 | Walk through a TLS 1.3 handshake. | Client hello with versions, cipher suites, key share, SNI, and ALPN; server hello with its key share; both derive keys; the server sends its certificate and a signature over the handshake, encrypted; the client verifies and finishes; one round trip; ephemeral keys mean a stolen private key does not decrypt old traffic |
| 3 | How does a client decide to trust a certificate? | Chain from leaf through intermediates to a root in its trust store; a valid signature at each step; the dialled name in the Subject Alternative Names; within its validity dates; usage allows server authentication; for internal services the private CA's bundle must be distributed |
| 4 | Terminate at the gateway, re-encrypt, or pass through: when do you choose each? | Termination lets the gateway route and authorize on HTTP and leaves the backend hop to the network; re-encryption adds encryption to the backend and requires the gateway to trust the backend's CA; passthrough keeps TLS end to end and limits the gateway to routing on SNI. Decide by who must see the request |
| 5 | What is mutual TLS, and how does it differ from a bearer token? | Both sides present certificates; the identity is bound to the connection and cannot be replayed from elsewhere; it identifies the workload, not the user; the usual design combines mutual TLS for the workload with a token for the user |
| 6 | How do workloads get and rotate certificates in a mesh? | Identity derived from namespace and service account, expressed as a SPIFFE ID; a control-plane CA signs short-lived certificates after checking the workload; a proxy or node agent holds the key and renews it; the trust bundle is distributed to every peer |
| 7 | What is the difference between node-to-node encryption and mutual TLS? | WireGuard or IPsec encrypts between nodes without touching workloads and stops sniffing on the wire, but every pod on a node is inside; mutual TLS proves each workload and makes identity-based authorization possible; they can be combined |
| 8 | A client gets a certificate error calling a service. How do you debug it? | Read the exact error first; `openssl s_client` with the right server name to see the presented chain and names; check for a missing intermediate, the client's trust bundle, the clock, the SNI sent, and version or cipher overlap; if a proxy is in the path, find where TLS actually ends |

**Scenario to practise.** The private CA that signs every internal service certificate has to be replaced. Describe the order of operations that avoids an outage, and how you would know it is safe to remove the old CA.

### Go further

Optional. Come back to these after the labs.

- TLS 1.2 handshake differences, and why older versions are disabled
- Session resumption and the replay risk of early data
- Encrypted Client Hello
- Post-quantum key exchange
- Certificate Transparency
- SPIRE and how it attests a workload before issuing an identity
- QUIC and HTTP/3

## Labs

Do these once you can answer the questions above.

- [ ] [STUDY_PLAN.md](../STUDY_PLAN.md), "Cilium advanced": the WireGuard encryption task and the Gateway API task
- [ ] [BUILD_PLAN.md](../BUILD_PLAN.md) stage 5, extension: the mutual TLS task
- [ ] [BUILD_PLAN.md](../BUILD_PLAN.md) stage 6: the gateway in front of the MCP server, and where it gets the caller's identity

## Sources

- [The Illustrated TLS 1.3 Connection](https://tls13.xargs.org/)
- [RFC 8446: The Transport Layer Security (TLS) Protocol Version 1.3](https://datatracker.ietf.org/doc/html/rfc8446)
- [Gateway API: TLS configuration](https://gateway-api.sigs.k8s.io/guides/tls/)
- [SPIFFE concepts](https://spiffe.io/docs/latest/spiffe-about/spiffe-concepts/)
- [Kubernetes: PKI certificates and requirements](https://kubernetes.io/docs/setup/best-practices/certificates/)
- [cert-manager documentation](https://cert-manager.io/docs/)
