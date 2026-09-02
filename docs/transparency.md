# Proving which image you host

Goal: let outsiders confirm that the **running** Janus Keycloak pods use an image that was **built from this repository**, without handing them a VPS shell or a kubeconfig.

## Do not do this

| Approach | Why it is a bad trade |
| --- | --- |
| Docker Compose / Docker socket on a shared VPS | Root-equivalent to the host; full process, volume, and secret access |
| Namespaced read-only Kubernetes account | Still exposes pod env (often secrets), ConfigMaps, mounts, sidecars, service topology, and other images. Tokens get copied and never rotate |

Read-only `get/list` on pods is **safer than Compose on a VPS**, but it is still too broad for “check the image SHA”.

## Recommended model (three layers)

### 1. Build-time provenance (this repo)

Every published image should be identifiable by **digest** (`repo@sha256:…`), not only by tag.

- CI prints and records the push digest.
- Prefer OCI provenance / SBOM attestations from the build (Sigstore / GitHub Artifact Attestations).
- Pin deploys by digest in the cluster (`image: …@sha256:…`).

Anyone can then check: “does digest `D` match a build of `janus-iam/janus-containers`?”

### 2. Runtime transparency endpoint (cluster / edge)

Expose a **tiny public JSON document** that only answers the question you want answered, for example:

```json
{
  "service": "keycloak",
  "namespace": "janus-auth",
  "image": "docker.io/example/keycloak_extended_a@sha256:…",
  "git_commit": "…",
  "built_at": "…",
  "attestation": "https://…"
}
```

Serve it from:

- a static file updated by the deploy pipeline, or
- a one-purpose HTTP handler / sidecar that reads the pod’s own image ID and nothing else.

No kube API. No pod listing. No env dump.

### Important: the JSON alone is not proof

Yes — if you are ill-intentioned, you can publish a **false** JSON that names a good digest `D` while actually running evil image `E`. Anyone who only trusts the file is tricked.

Treat the endpoint as a **claim**, not a trust root.

| What outsiders can verify | What they cannot verify from your JSON |
| --- | --- |
| Digest `D` was built from this repo / commit (Sigstore / GitHub OIDC attestation) | That your servers are *actually executing* `D` right now |
| You *claim* to run `D` | That the claim matches runtime |

Build attestations stop “I built this magic binary off-repo.” They do **not** stop “I lie about what I run.”

### 3. Independent verification recipe

Publish a short public checklist:

1. `curl https://auth.example.com/.well-known/janus-image.json` → claimed digest `D` (**untrusted claim**)
2. Verify signature / attestation for `D` against this GitHub org/repo (**trusted if Sigstore/GitHub identity holds**)
3. Optionally pull `image@D` and compare filesystem / SBOM (advanced)
4. For **runtime honesty**, require something outside your sole control (see below)

Steps 1–3 prove **provenance of the claimed digest**. They do not by themselves prove **hosting**.

### Closing the “fake JSON” gap

Pick one or combine:

1. **Signed claim + public expectation** — still forgeable by you, but lies become explicit and timestamped (Rekor / release notes). Social accountability, not crypto proof of runtime.
2. **Independent observer** — auditor, customer, or monitor with narrow evidence of the live digest (privileged peek, or your own admission controller + external log sink you do not solely control).
3. **Hardware attestation (TEE)** — SEV-SNP / TDX style remote attestation of the running workload. Strong, uncommon for a normal Keycloak VPS.
4. **Reproducible builds** — outsiders rebuild the same commit and get the same digest. Proves the *image*, not that *you* run it.
5. **Do not overclaim** — document clearly: “this JSON is our statement; attestations prove the image build; runtime verification needs an audit.”

Honest framing beats a fake sense of crypto proof.

## If you still want Kubernetes RBAC

Only as a last resort, and still narrower than “read the namespace”:

- Dedicated ServiceAccount
- Role limited to `get`/`list` on `pods` **or** better: only on a custom resource / ConfigMap that holds the transparency JSON
- No `secrets`, `configmaps` (except that one), `exec`, `port-forward`, `pods/log` unless strictly needed
- Short-lived tokens (projected SA tokens), never long-lived kubeconfig files in chat/email
- Separate audit namespace; do not reuse admin contexts

Even then, prefer the public JSON endpoint: same proof, far less blast radius.

## Safe VPS alternatives to Docker Compose

If the question is “how should *we* run this on a VPS?” rather than “how do outsiders inspect us?”:

| Option | Fit |
| --- | --- |
| **k3s / k0s** (single node) | Best if you already think in Deployments and want digest pins + RBAC |
| **Podman Quadlet + systemd** | Rootless-friendly, no Compose daemon, good for one or two services |
| **Docker Compose rootless** | Acceptable for private ops; never share the host with outsiders |
| **Managed Kubernetes** | Same transparency pattern; less host babysitting |

None of these replace a transparency endpoint for public proof.

## Minimal decision for Janus

1. Keep publishing multi-arch images from this repo with **recorded digests** (and attestations when enabled in CI).
2. In the cluster that *runs* Keycloak, publish a **public digest claim** (JSON)—not a shared kubeconfig. Label it as a claim.
3. Tell verifiers to check **attestations** for that digest; never trust the JSON alone.
4. If you need to prove runtime against a hostile-operator threat model, add an independent audit path (or TEE)—the public file cannot carry that burden.
