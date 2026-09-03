# VPS digest status (no `docker` group for verifiers)

Publish running image identities without giving outsiders Docker or SSH.

1. Collector (this host only) reads `docker.sock` and writes `images.json`.
2. Nginx serves that file. It **does not** mount the socket.

```bash
cd examples/vps-digest-status
docker compose up -d
curl -sS http://127.0.0.1:8088/images.json
```

Put nginx/Caddy in front with TLS if this should be public. Bind is localhost by default.

The JSON includes name, compose service, image reference, image ID, and repo digests. It does not include `Env`.
