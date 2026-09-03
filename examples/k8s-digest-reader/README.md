# Kubernetes image readers

**Prefer [`../k8s-digest-publisher`](../k8s-digest-publisher)** if verifiers must not see pod env vars. That path publishes a digest-only ConfigMap.

`role.yaml` here is the older “supplier peek”: namespaced `get`/`list` on Pods and Deployments. Kubernetes returns the **full** object (env names, `secretKeyRef`, mounts). Use it only when that spec is already non-sensitive.
