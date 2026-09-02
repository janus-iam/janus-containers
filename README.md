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

To let someone verify that **impersonation is off on a live instance**, point them at Keycloak Server info (feature list) or a failing impersonation API call—not at Docker Compose or a Kubernetes account. See [docs/transparency.md](docs/transparency.md).

CI also records image digests on each build (useful for pinning deploys; optional for the impersonation claim).

## Differences to come

### Cache

This will package a `cache-ispn-jdbc-ping.xml` for setting up Infinispan/JGroups discovery via the `JDBC` ping protocol.
