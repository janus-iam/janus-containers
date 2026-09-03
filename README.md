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

To verify that a live instance runs a build with **impersonation disabled**, use the supply-chain path: match the **running image digest** (Kubernetes `imageID`, or a VPS digest-only page) to a CI-built digest from this repo (see [docs/transparency.md](docs/transparency.md)). Server info is optional corroboration and requires admin auth.

CI records image digests on each build so deploys can be pinned with `image@sha256:…`.

## Differences to come

### Cache

This will package a `cache-ispn-jdbc-ping.xml` for setting up Infinispan/JGroups discovery via the `JDBC` ping protocol.
