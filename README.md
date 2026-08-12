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
- `recovery-codes`

## Differences to come

### Cache

This will package a `cache-ispn-jdbc-ping.xml` for setting up Infinispan/JGroups discovery via the `JDBC` ping protocol.
