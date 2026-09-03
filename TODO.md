- [x] Proper README (use https://github.com/p2-inc/phasetwo-containers as reference)

- [ ] Harden Containerfile security ?

- [x] Prove impersonation is disabled (supply-chain / image digest)
  - Real goal: show Keycloak impersonation is off (`--features-disabled=impersonation` in this build)
  - Decision: primary proof = running k8s image digest ↔ CI digest from this Containerfile (see `docs/transparency.md`)
  - k8s verifiers: digest-only ConfigMap (`examples/k8s-digest-publisher`) — RBAC cannot hide env on Pod get
  - Optional: namespaced full pod read (`examples/k8s-digest-reader`) if spec leakage is acceptable
  - VPS: do not use `docker` group; local socket collector + nginx digest page (`examples/vps-digest-status`)
  - Rejected as primary proof: self-hosted feature JSON; Compose/Docker socket / docker group for verifiers
  - Optional: Keycloak Server info / impersonation API (needs admin auth; not the supply-chain root)
