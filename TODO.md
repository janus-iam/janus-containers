- [x] Proper README (use https://github.com/p2-inc/phasetwo-containers as reference)

- [ ] Harden Containerfile security ?

- [x] Prove impersonation is disabled (supply-chain / image digest)
  - Real goal: show Keycloak impersonation is off (`--features-disabled=impersonation` in this build)
  - Decision: primary proof = running k8s image digest ↔ CI digest from this Containerfile (see `docs/transparency.md`)
  - OK: namespaced RO k8s account limited to pods/deployments for invited verifiers (supplier way; better than Compose on a VPS)
  - Rejected as primary proof: self-hosted feature JSON; Compose/Docker socket on a VPS
  - Optional: Keycloak Server info / impersonation API (needs admin auth; not the supply-chain root)
