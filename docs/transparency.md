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

## VPS / Docker Compose alternative

Same supply-chain goal, no Kubernetes.

### Do not put verifiers in the `docker` group

Membership in `docker` is effectively **root on the host** (mount `/`, start privileged containers, read any file via a container). It is not a “read-only Docker user.” There is no safe first-class Docker RBAC on the engine socket comparable to Kubernetes Roles.

### Pattern that works: local agent + public digest list

Only a **local** process may touch the Docker socket. Verifiers hit an HTTP surface that returns **only** name + image digest (and maybe compose service name)—nothing else.

Minimal open-source DIY:

```bash
# cron every minute as root / docker-capable user — not exposed to verifiers
docker inspect $(docker ps -q) --format '{{.Name}} {{.Image}} {{.Id}}' \
  > /var/www/transparency/images.txt
# or JSON with RepoDigests / Image ID
```

Serve `/var/www/transparency/` with nginx (static files only). No docker.sock in the web container.

Slightly nicer: a tiny container that mounts `docker.sock`, writes digests to a volume, and a second container (nginx) that only serves that volume—**never** mounts the socket.

### Off-the-shelf UIs (use carefully)

| Tool | Fit |
| --- | --- |
| **DIY static JSON + nginx** | Best match for “show digests only” |
| **[WUD – What’s Up Docker](https://getwud.github.io/wud/)** | OSS dashboard of running images/tags; needs docker.sock on the *agent*; put auth in front; disable update triggers for verifiers; still may show more than a digest |
| Portainer / Dockge / similar | Ops panels—too powerful for external proof even with “RO” roles |
| Giving an SSH user + `docker` group | Equivalent to sharing root |

Prefer the static digest page (or a one-purpose API) over inviting people into Docker tooling.

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
| Shared Docker Compose / Docker socket / `docker` group on a VPS | Host-level access; Docker has no safe field-level “digest only” user |
| Trusting a self-hosted `"impersonation": false` JSON alone | Easy to fake; no link to the artifact |
| Floating tags (`:26.7.2`) without digest pins | Tag can move; digest cannot |

## Honest limits

- Digest proof shows you run **artifact D**. It shows impersonation is off **if D was built from this Containerfile** (attestation / reproducible rebuild).
- A hostile operator can still point verifiers at a different host or lie about which workload to inspect. Invited auditors need a known URL/namespace.
- Server info alone is weaker than digest pinning for supply-chain claims.
- A VPS digest webpage is still a **claim about that host**; keep the collector honest and the page limited to digests.

## Decision for Janus

1. Keep `impersonation` in `--features-disabled` (done).
2. Treat **running image digest** as the primary proof; CI records digests for comparison.
3. On Kubernetes: namespaced RO pod/deploy read, or a digest-only CRD/API if env leakage matters.
4. On a VPS: **not** `docker` group—use a local socket agent + public digest list (static file / tiny API); optional WUD behind auth for richer UI.
5. Use Server info / impersonation API only as optional corroboration for Keycloak admins.
