# Digest-only view of a `kubectl get pods -o json` document.
# Keeps pod name + container image identity. Drops env, mounts, commands.
{
  generated_by: "janus-containers/examples/k8s-digest-publisher",
  generated_at: (now | strftime("%Y-%m-%dT%H:%M:%SZ")),
  namespace: ((.items[0].metadata.namespace) // $namespace),
  pods: [
    .items[]
    | {
        name: .metadata.name,
        containers: [
          ((.status.containerStatuses // [])[])
          | {
              name: .name,
              image: .image,
              image_id: .imageID
            }
        ]
      }
  ]
}
