# OAuth, OIDC, and JWT study guide

Covers how delegated access works: the OAuth roles and flows, OpenID Connect, how a JSON Web Token is validated, and how a workload gets a token without a stored secret. MCP authorization and agent identity are built on these.

Study the key fundamentals, and make sure you can answer the questions at the end of the Study part, before you start the Labs part.

## Study

### Key fundamentals

| # | Concept | What to understand |
| --- | --- | --- |
| 1 | Roles | Authentication says who you are, authorization says what you may do. OAuth is about authorization: a resource owner (the user) lets a client (an application or agent) call a resource server (an API) with a token issued by an authorization server |
| 2 | Tokens | An access token is short-lived and is what the API accepts; a refresh token gets new access tokens and never goes to an API; an ID token tells the client who logged in and is not for calling APIs |
| 3 | Flows | Authorization code with PKCE whenever a user is involved: the user logs in at the authorization server, the client receives a code and exchanges it, and PKCE stops a stolen code from being used. Client credentials when a service acts as itself with no user |
| 4 | OAuth 2.1 | A consolidation of security practice: PKCE on every authorization code flow, no implicit or password grant, exact matching of redirect URIs, and no tokens in query strings |
| 5 | JWT structure | Header, payload, and signature, each base64url-encoded; signed, not encrypted, so anyone can read it; the usual claims are `iss`, `sub`, `aud`, `exp`, `iat`, and `scope` |
| 6 | Validating a JWT | Verify the signature with the issuer's published keys (JWKS, chosen by `kid`); accept only the algorithms you expect; check that `iss` is the issuer you trust, that `aud` names this service, and that the token has not expired; only then use scopes and claims |
| 7 | Scope and audience | Scope says what the token allows, audience says which service it is for; a token for one service must be rejected by another; a resource indicator lets a client ask for a token for one specific resource |
| 8 | OpenID Connect | An identity layer on OAuth: the ID token, a discovery document at `/.well-known/openid-configuration`, and a published key set; used for single sign-on and to authenticate users to the Kubernetes API |
| 9 | Token exchange | A service swaps the token it received for a new one with a narrower scope and a different audience; the new token can record both the user and the service acting for them; the alternative, forwarding the same token downstream, defeats audience checks |
| 10 | Workload identity | A workload proves itself with a token its platform issues, such as a Kubernetes service account token, which is a short-lived JWT with an audience; a cloud provider or another issuer that trusts the cluster exchanges it for credentials, so no key is stored |
| 11 | Bearer tokens | Whoever holds one can use it; the defences are short lifetimes, TLS everywhere, audience restriction, never logging tokens, and tokens bound to the sender's key or certificate |
| 12 | How MCP uses it | An MCP server is a resource server; it publishes metadata that points to its authorization server; the client runs authorization code with PKCE and names the server as the resource; the server accepts only tokens issued for itself and does not pass them on |

### Reading

1. Rows 1 to 4: the overview pages at [oauth.net](https://oauth.net/2/), including the one on [OAuth 2.1](https://oauth.net/2.1/), then section 2 of [RFC 9700, Best Current Practice for OAuth 2.0 Security](https://datatracker.ietf.org/doc/html/rfc9700).
2. Rows 5 and 6: [RFC 7519, JSON Web Token](https://datatracker.ietf.org/doc/html/rfc7519), sections 3 and 4, and [RFC 8725, JSON Web Token Best Current Practices](https://datatracker.ietf.org/doc/html/rfc8725).
3. Row 8: [OpenID Connect Core](https://openid.net/specs/openid-connect-core-1_0.html), sections 1 to 3.
4. Row 9: [RFC 8693, OAuth 2.0 Token Exchange](https://datatracker.ietf.org/doc/html/rfc8693), sections 1 and 2.
5. Row 10: Kubernetes documentation on [service accounts](https://kubernetes.io/docs/concepts/security/service-accounts/).
6. Row 12: the [MCP authorization specification](https://modelcontextprotocol.io/specification/2026-07-28/basic/authorization).

### Drills

Short checks that need only paper, `kubectl`, and a kind cluster.

- [ ] Decode a JWT by hand: split it at the dots, base64url-decode the first two parts, and name every claim
- [ ] Write the checks a resource server makes on a token, in order, and say what an attacker gains if each one is skipped
- [ ] Draw the authorization code flow with PKCE as a sequence between browser, client, authorization server, and API; mark everything that passes through the browser
- [ ] Run `kubectl create token` for a service account with an audience, decode the result, and find the issuer, subject, audience, and expiry
- [ ] Fetch the cluster's discovery document and key set with `kubectl get --raw /.well-known/openid-configuration` and `kubectl get --raw /openid/v1/jwks`, and find the key that signed that token

### Pitfalls

- An ID token is for the client. Sending it to an API as if it were an access token is a design error.
- Decoding is not validating. The payload of a JWT is readable by anyone and proves nothing until the signature is checked.
- Skipping the audience check lets a token issued for one service be replayed against another.
- Trusting the algorithm named in the token's own header. Accept only the algorithms you configured.
- Long-lived tokens in logs, URLs, or environment variables.
- Forwarding the caller's token to the next service instead of exchanging it.
- Scopes are coarse. A fine-grained decision still needs a check at the resource.

### Questions you should be able to answer

After studying this guide, you should be able to answer the questions below. Answer each out loud, without notes, in about two minutes. The right-hand column is a checklist of what a strong answer covers, not a script.

| # | Question | A strong answer covers |
| --- | --- | --- |
| 1 | What is the difference between OAuth and OpenID Connect? | OAuth delegates access to an API and says nothing reliable about who the user is; OpenID Connect adds an ID token and discovery so a client can authenticate the user; access tokens are for APIs, ID tokens are for the client |
| 2 | Walk through the authorization code flow with PKCE. Why PKCE? | Redirect to the authorization server with a code challenge; the user logs in and consents; the client gets a code back and exchanges it with the verifier; tokens never pass through the browser; PKCE makes an intercepted code useless without the verifier |
| 3 | What are access, refresh, and ID tokens for, and who should see each? | Access token: short-lived, sent to the API; refresh token: kept by the client to get new access tokens, never sent to an API; ID token: read by the client to learn who logged in |
| 4 | How does an API validate a JWT? | Signature against the issuer's key set, with the key chosen by `kid`; algorithm pinned; issuer, audience, and expiry checked, with a small allowance for clock skew; then scopes and claims; cache the key set and handle key rotation |
| 5 | What are scope and audience, and what goes wrong without an audience check? | Scope is what, audience is where; without the check, any service that receives a token can replay it against another service that trusts the same issuer |
| 6 | How should a service call another service on behalf of a user? | Exchange the incoming token for one that is scoped down, bound to the downstream audience, and short-lived, recording both the user and the acting service; do not forward the original; use the service's own identity when no user context is needed |
| 7 | How does a pod authenticate to a cloud API or another service without a stored secret? | A projected service account token: short-lived, audience-bound, signed by the cluster and rotated by the kubelet; the other side trusts the cluster's issuer and exchanges the token for its own credentials; nothing long-lived to leak |
| 8 | What are the risks of bearer tokens, and how do you reduce them? | Possession is enough, so theft is the risk; short lifetimes, TLS, audience restriction, no tokens in logs or URLs, rotation of refresh tokens, and sender-constrained tokens where the stakes justify them |

**Design prompt to practise.** An agent acts for a user and calls three MCP servers, one of which calls a downstream API. Describe every token involved: who issues it, its audience, its lifetime, what the receiver checks, and what an attacker gains by stealing it.

### Go further

Optional. Come back to these after the labs.

- Sender-constrained tokens: DPoP and certificate-bound tokens
- Opaque tokens, introspection, and revocation
- Client registration, including dynamic registration
- The device authorization flow
- Fine-grained authorization models and policy engines
- SAML, for the single sign-on systems that still use it

## Labs

Neither plan has a lab built around issuing tokens, so the drills above are the hands-on part. This guide supports these tasks.

- [ ] [BUILD_PLAN.md](../BUILD_PLAN.md) stage 6: the external-authorization service, which decides on the caller's identity
- [ ] [BUILD_PLAN.md](../BUILD_PLAN.md) stage 8: the attack suite, when you reason about what a stolen credential allows

## Sources

- [OAuth 2.0](https://oauth.net/2/)
- [OAuth 2.1](https://oauth.net/2.1/)
- [RFC 9700: Best Current Practice for OAuth 2.0 Security](https://datatracker.ietf.org/doc/html/rfc9700)
- [RFC 7519: JSON Web Token](https://datatracker.ietf.org/doc/html/rfc7519)
- [RFC 8725: JSON Web Token Best Current Practices](https://datatracker.ietf.org/doc/html/rfc8725)
- [OpenID Connect Core 1.0](https://openid.net/specs/openid-connect-core-1_0.html)
- [RFC 8693: OAuth 2.0 Token Exchange](https://datatracker.ietf.org/doc/html/rfc8693)
- [Kubernetes: Service accounts](https://kubernetes.io/docs/concepts/security/service-accounts/)
- [MCP authorization specification](https://modelcontextprotocol.io/specification/2026-07-28/basic/authorization)
