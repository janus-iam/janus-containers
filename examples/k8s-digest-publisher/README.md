# Kubernetes digest-only reader

Kubernetes RBAC cannot grant “image digest but not env.” `get`/`list` on Pods always returns the full object.

This example publishes **only** name + image + `imageID` into ConfigMap `running-image-digests`. Verifiers `get` that object and never receive pod specs.

```bash
# in the auth namespace
kubectl apply -n janus-auth -f install.yaml

# after the first CronJob run (up to 1 minute), or create a Job from it:
kubectl -n janus-auth create job --from=cronjob/image-digest-publisher digest-now

kubectl -n janus-auth get configmap running-image-digests \
  -o jsonpath='{.data.images\.json}{"\n"}'
```

Compare each `image_id` to the digest in the GitHub Actions job summary for this repo.

To invite a person instead of the example ServiceAccount, edit the `image-digest-reader` RoleBinding subjects (`User` / `Group`).

The publisher ServiceAccount can still list Pods (it is the local collector). Do not give that account to verifiers.
