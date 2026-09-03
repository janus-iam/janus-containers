ARG KEYCLOAK_VERSION=26.7.2
# renovate: datasource=github-releases depName=FortuneN/kete
ARG KETE_VERSION=2026.03.23.23.48

FROM quay.io/keycloak/keycloak:${KEYCLOAK_VERSION} AS builder

ARG KETE_VERSION

ADD --chown=keycloak:keycloak --chmod=644 https://github.com/FortuneN/kete/releases/download/${KETE_VERSION}/kete.jar /opt/keycloak/providers/kete.jar

RUN /opt/keycloak/bin/kc.sh build \
  --db=postgres \
  --http-relative-path=/auth \
  --health-enabled=true \
  --metrics-enabled=true \
  --tracing-enabled=true \
  --event-metrics-user-enabled=true \
  --spi-events-listener--kete--enabled=true \
  --spi-events-listener--kete--metrics-enabled=true \
  --features-disabled="organization,workflows,impersonation"

FROM quay.io/keycloak/keycloak:${KEYCLOAK_VERSION}

ARG KEYCLOAK_VERSION
ARG KETE_VERSION
LABEL org.opencontainers.image.title="Janus Keycloak" \
      org.opencontainers.image.description="Keycloak image extended for Janus IAM" \
      org.opencontainers.image.source="https://github.com/janus-iam/janus-containers" \
      org.opencontainers.image.vendor="janus-iam" \
      org.keycloak.version="${KEYCLOAK_VERSION}" \
      org.janus.kete.version="${KETE_VERSION}"

COPY --from=builder /opt/keycloak/ /opt/keycloak/

ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]
