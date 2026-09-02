- [x] Proper README (use https://github.com/p2-inc/phasetwo-containers as reference)

- [ ] Harden Containerfile security ?

- [x] Prove hosted image SHA without shared kubeconfig / Compose
  - Decision: publish digests + attestations from CI; expose a public runtime transparency JSON from the cluster (see `docs/transparency.md`)
  - Rejected: namespaced RO k8s accounts and shared Docker Compose on a VPS (too much blast radius for “check the SHA”)
