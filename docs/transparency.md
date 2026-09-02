# Proving impersonation is disabled (supply-chain way)

Goal: let people verify that the Keycloak you run was **built with impersonation disabled**.

This image disables it at **build** time:

```text
--features-disabled="organization,workflows,impersonation"
```

That property is baked into the image. The standard supply-chain way to prove you host that build is the **image digest** the cluster is running—not a hand-written status JSON, and not Docker Compose on a VPS.

## Proof chain

```text
Containerfile (--features-disabled=impersonation)
        ↓ CI build + push
image@sha256:D  (+ provenance / SBOM when enabled)
        ↓ deploy by digest (not by floating tag)
Pod status.containerStatuses[].imageID == sha256:D
        ↓ verifier checks digest D
D matches a build of this repo ⇒ impersonation was disabled in that build
```

So the claim “impersonation is off” reduces to:

1. This repo’s `Containerfile` disables it.
2. Digest `D` was built from that recipe (CI record / attestation).
3. The live workload runs `…@sha256:D` (Kubernetes image ID).

That is the supplier / supply-chain model: **identity of the artifact**, not a separate “feature flag” API.

## How verifiers see the running digest

### Preferred: narrow Kubernetes read on the auth namespace

A namespaced account that can only `get`/`list` `pods` (and optionally `deployments`) so people can read:

```bash
kubectl -n <auth-ns> get pods -o jsonpath='{range .items[*]}{.metadata.name}{" "}{.status.containerStatuses[*].imageID}{"\n"}{end}'
```

Compare that digest to the one published in the GitHub Actions job summary for this image.

This is **better than Docker Compose on a VPS** (no host/Docker socket) and is the normal way auditors check “what binary is scheduled.”

Harden it:

- One namespace only; no cluster-wide read
- No `secrets`, `exec`, `port-forward`, `pods/log` unless required
- Short-lived tokens; rotate; never paste long-lived kubeconfigs into chat
- **RBAC cannot hide env vars while allowing digest reads** (see below)

### Can RBAC show only the image digest, not env?

**No.** Kubernetes RBAC authorizes whole resources/subresources (`pods`, `pods/status`, …), not JSON fields. If someone can `get`/`list` pods, the API returns the **full** Pod object, including `spec.containers[].env`, volume mounts, service account name, etc.

Client-side tricks (`-o jsonpath=…imageID`) only change what *kubectl prints*; they do not stop `kubectl get pod -o yaml`.

Practical options if plaintext env leakage is unacceptable:

| Approach | Effect |
| --- | --- |
| Keep secrets out of pod env (`valueFrom.secretKeyRef` / mounted files; never `value: …`) | Pod YAML shows secret *names*, not secret *data* (still some metadata leakage) |
| Deny `get`/`list` on `secrets` and `configmaps` | Stops reading secret bodies; does **not** strip env from the Pod object |
| Controller → small CRD/ConfigMap that only stores `{image, digest}` + RBAC on that object only | Verifiers never need `get pods` |
| Read-only aggregating API / reverse proxy that returns only `imageID` | Same idea; you maintain the filter |

So: use namespaced pod read when the Pod spec is already non-sensitive; if it is not, publish digest via a **dedicated object or endpoint**, not raw `get pods`.

### Also publish the digest from CI (this repo)

Build workflows already record the pushed digest in the job summary and can emit provenance/SBOM. Pin Deployments with `image: …@sha256:…` so the running ID cannot drift from a moving tag.

## Optional corroboration (not the supply-chain root of trust)

### Keycloak Server info

`GET /auth/admin/serverinfo` shows feature flags, but it **requires admin auth** (401 without Bearer, 403 if not admin). Useful as a second check for someone who already has a Keycloak admin account; it is not a public substitute for the digest chain.

### Impersonation API behavior

`POST /auth/admin/realms/{realm}/users/{id}/impersonation` should fail when the feature is build-disabled. Same caveat: needs privileged credentials, and a hostile operator can still fake HTTP.

## What to avoid

| Approach | Why |
| --- | --- |
| Shared Docker Compose / Docker socket on a VPS | Host-level access; not how you prove an image digest |
| Trusting a self-hosted `"impersonation": false` JSON alone | Easy to fake; no link to the artifact |
| Floating tags (`:26.7.2`) without digest pins | Tag can move; digest cannot |

## Honest limits

- Digest proof shows you run **artifact D**. It shows impersonation is off **if D was built from this Containerfile** (attestation / reproducible rebuild).
- A hostile operator can still point verifiers at a different cluster or lie about which namespace to inspect. Narrow RO access to the real auth namespace closes that for invited auditors.
- Server info alone is weaker than digest pinning for supply-chain claims.

## Decision for Janus

1. Keep `impersonation` in `--features-disabled` (done).
2. Treat **running image digest** as the primary proof; CI records digests for comparison.
3. Offer a **namespaced read-only Kubernetes account** (pods/deployments) for people who should verify what you host—prefer that over Compose on a VPS.
4. Use Server info / impersonation API only as optional corroboration for Keycloak admins.
