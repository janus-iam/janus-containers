- [x] Proper README (use https://github.com/p2-inc/phasetwo-containers as reference)

- [ ] Harden Containerfile security ?

- [x] Prove impersonation is disabled without shared kubeconfig / Compose
  - Real goal: show that Keycloak user impersonation is off (build `--features-disabled=impersonation`)
  - Decision: public Containerfile + live Server info / impersonation API check via a minimal Keycloak account (see `docs/transparency.md`)
  - Rejected: namespaced RO k8s accounts and shared Docker Compose on a VPS (wrong tool / too much blast radius)
  - CI still records image digests for deploy pinning; not required for the impersonation claim
