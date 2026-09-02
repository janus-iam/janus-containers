- [x] Proper README (use https://github.com/p2-inc/phasetwo-containers as reference)

- [ ] Harden Containerfile security ?

- [x] Prove hosted image SHA without shared kubeconfig / Compose
  - Decision: publish digests + attestations from CI; expose a public runtime transparency JSON as a *claim* (see `docs/transparency.md`)
  - Rejected: namespaced RO k8s accounts and shared Docker Compose on a VPS (too much blast radius for “check the SHA”)
  - Note: JSON alone can lie; attestations prove build provenance of a digest, not that the operator runs it—runtime proof needs audit/TEE/independent observer
