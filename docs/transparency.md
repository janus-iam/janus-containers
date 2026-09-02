# Proving impersonation is disabled

Goal: let people verify that this Janus Keycloak build has **user impersonation turned off**, without a shared VPS shell or a Kubernetes account.

This image disables it at **build** time:

```text
--features-disabled="organization,workflows,impersonation"
```

That is stronger than only removing the admin “impersonate” permission: the Keycloak `impersonation` feature is not available in the binary configuration.

## What to show people (simple → stronger)

### 1. Public build recipe (already true)

Anyone can read this repository’s `Containerfile` and see `impersonation` in `--features-disabled`. That is a public commitment about **what the image is built to do**.

### 2. Live Keycloak server info (best practical check)

Keycloak exposes feature state on the admin **Server info** API / console (features enabled vs disabled), typically via:

- Admin Console → Server info (feature list), or
- `GET /auth/admin/serverinfo` (with an admin access token; path prefix matches this image’s `--http-relative-path=/auth`)

Have the verifier confirm `impersonation` appears as **disabled**.

Give them a **Keycloak account**, not a kubeconfig:

- realm (or master) user with only enough rights to open Server info / call `serverinfo`
- no pod access, no Docker socket, no cluster secrets

That answers “is impersonation off on the instance I care about?” with far less blast radius than namespace-wide Kubernetes read.

### 3. Behavioral check (optional)

With a token that would normally be allowed to impersonate, call:

```http
POST /auth/admin/realms/{realm}/users/{user-id}/impersonation
```

When the feature is build-disabled, impersonation should fail (feature unavailable), not create an impersonation session. Document the expected error for your Keycloak version so outsiders can reproduce it.

## What not to bother with (for this goal)

| Approach | Why it is the wrong tool here |
| --- | --- |
| Shared Docker Compose / Docker socket on a VPS | Proves nothing specific about impersonation; gives host-level access |
| Namespaced read-only Kubernetes account | Lets people read image digests/env; still overkill and leaky if the question is only “is impersonation off?” |
| Public JSON that only says `"impersonation": false` | Easy to fake; prefer Server info or the impersonation API |

Full image-digest transparency (attestations, pinned digests) is still useful for supply-chain trust, but it is **not required** to answer the impersonation question. Prefer Keycloak’s own feature reporting.

## Honest limits

- A malicious operator can still run a **different** image or proxy fake admin responses. No public file or API they solely control is absolute proof against that threat model.
- For normal “show customers / auditors we disabled it” trust, **Containerfile + live Server info** is the right level.
- Against a hostile-host model you need an independent observer or stronger runtime attestation—not a broader kubeconfig.

## Decision for Janus

1. Keep `impersonation` in `--features-disabled` in this repo (done).
2. Tell verifiers to check **Server info** (or the impersonation API), using a minimal Keycloak admin-scoped account if needed.
3. Do **not** hand out Docker Compose hosts or Kubernetes read accounts for this claim.
