#!/bin/sh
# Prove collect.sh emits identity fields only (no Env) and the page lists them.
set -eu
cd "$(dirname "$0")"

bin=$(mktemp -d)
out=$(mktemp -d)
trap 'rm -rf "$bin" "$out"' EXIT

cat > "$bin/docker" <<'EOS'
#!/bin/sh
# Minimal docker stub for collect.sh
set -eu
cmd=$1
shift
case "$cmd" in
  ps)
    echo cid1
    ;;
  inspect)
    cid=$2
    fmt=$3
    case "$fmt" in
      '{{.Name}}') echo /janus-keycloak-1 ;;
      '{{.Config.Image}}') echo example/keycloak_extended_a:26.7.3 ;;
      '{{.Image}}') echo sha256:aaa111bbb222ccc333ddd444eee555fff666aaabbbcccdddeeefff0001112222 ;;
      '{{index .Config.Labels "com.docker.compose.service"}}') echo keycloak ;;
      *)
        echo "unexpected inspect format: $fmt" >&2
        exit 1
        ;;
    esac
    ;;
  image)
    echo 'example/keycloak_extended_a@sha256:aaa111bbb222ccc333ddd444eee555fff666aaabbbcccdddeeefff0001112222'
    ;;
  *)
    echo "unexpected docker command: $cmd $*" >&2
    exit 1
    ;;
esac
EOS
chmod +x "$bin/docker"

PATH="$bin:$PATH" OUT="$out/images.json" ./collect.sh

python3 - "$out/images.json" <<'PY'
import json, sys
path = sys.argv[1]
raw = open(path, encoding="utf-8").read()
doc = json.loads(raw)
assert doc["generated_by"] == "janus-containers/examples/vps-digest-status"
assert len(doc["containers"]) == 1
c = doc["containers"][0]
assert c["name"] == "janus-keycloak-1"
assert c["compose_service"] == "keycloak"
assert c["image"] == "example/keycloak_extended_a:26.7.3"
assert c["image_id"].startswith("sha256:")
assert c["repo_digests"] == [
    "example/keycloak_extended_a@sha256:aaa111bbb222ccc333ddd444eee555fff666aaabbbcccdddeeefff0001112222"
]
assert set(c) == {"name", "compose_service", "image", "image_id", "repo_digests"}
for leaked in ("Env", "Env=", "PASS", "secret", "Mounts", "Cmd"):
    assert leaked not in raw, f"leaked {leaked!r}"
print("vps-digest-status: collect.sh digest-only JSON ok")
PY

python3 - index.html testdata/images.json <<'PY'
from pathlib import Path
import sys
html = Path(sys.argv[1]).read_text(encoding="utf-8")
assert 'fetch("images.json"' in html
assert "repo_digests" in html
assert "No environment variables" in html
print("vps-digest-status: index.html loads images.json")
PY
