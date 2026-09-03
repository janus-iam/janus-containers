#!/bin/sh
# Prove the publisher drops env / secrets and keeps only image identity.
set -eu
cd "$(dirname "$0")"

out=$(mktemp)
trap 'rm -f "$out"' EXIT

PODS_JSON=testdata/pods.json APPLY=0 OUT="$out" ./publish.sh >/dev/null

python3 - "$out" <<'PY'
import json, sys

path = sys.argv[1]
doc = json.load(open(path, encoding="utf-8"))
raw = open(path, encoding="utf-8").read()

assert doc["generated_by"] == "janus-containers/examples/k8s-digest-publisher"
assert doc["namespace"] == "janus-auth"
assert len(doc["pods"]) == 1
pod = doc["pods"][0]
assert pod["name"] == "keycloak-0"
assert len(pod["containers"]) == 1
c = pod["containers"][0]
assert c["name"] == "keycloak"
assert c["image"] == "example/keycloak_extended_a:26.7.3"
assert c["image_id"].endswith("sha256:aaa111bbb222ccc333ddd444eee555fff666aaabbbcccdddeeefff0001112222")
assert set(c) == {"name", "image", "image_id"}
assert set(pod) == {"name", "containers"}

for leaked in (
    "super-secret-should-not-leak",
    "KC_DB_PASSWORD",
    "KC_DB_USERNAME",
    "spec",
    "env",
    "value",
):
    assert leaked not in raw, f"leaked {leaked!r} into digest JSON"

print("k8s-digest-publisher: digest-only filter ok")
PY

python3 - install.yaml <<'PY'
from pathlib import Path
text = Path("install.yaml").read_text(encoding="utf-8")
assert "image_id: .imageID" in text
assert "resourceNames: [\"running-image-digests\"]" in text
# Verifier role must not grant pod reads.
reader = text.split("name: image-digest-reader", 1)[1]
assert 'resources: ["pods"]' not in reader
assert 'resources: ["configmaps"]' in reader
print("k8s-digest-publisher: installer keeps digest-only verifier Role")
PY
