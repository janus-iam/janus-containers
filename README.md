# Janus Docker image

Builds the base Janus Keycloak Docker image that is used in our cluster.

## Extensions

This distribution contains the following extensions:

| Component              | Status             | Repository                                              | Description                                                              |
| ---------------------- | ------------------ | ------------------------------------------------------- | ------------------------------------------------------------------------ |
| Kete                   | :white_check_mark: | https://github.com/FortuneN/kete                        | Streams matched Keycloak events to various destinations and formats.     |

## Disabled features

The image is built with the following Keycloak features disabled (`--features-disabled`):

- `organization`
- `workflows`
- `impersonation`

In addition to the [features disabled by default](https://www.keycloak.org/server/features#_disabled_by_default)

## Verifying what we build and host

Image tags move; **digests** do not. CI records the pushed digest for each build.

To let people check a claimed running digest **without** Docker Compose access or a Kubernetes account, use digests + a public transparency document. That document is a **claim**—attestations prove the image was built from this repo; they do not by themselves prove the host is truthful about runtime. See [docs/transparency.md](docs/transparency.md).

**Do not** share a VPS Docker socket or a namespaced read-only kubeconfig for this: both leak far more than an image SHA.

## Differences to come

### Cache

This will package a `cache-ispn-jdbc-ping.xml` for setting up Infinispan/JGroups discovery via the `JDBC` ping protocol.
