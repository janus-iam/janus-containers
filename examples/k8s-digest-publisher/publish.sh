#!/bin/sh
# Publish running pod image identities to a digest-only ConfigMap.
# Verifiers get that ConfigMap; they never need get/list on Pods.
set -eu

NAMESPACE="${NAMESPACE:-janus-auth}"
CM_NAME="${CM_NAME:-running-image-digests}"
OUT="${OUT:-/tmp/running-image-digests.json}"
PODS_JSON="${PODS_JSON:-}"
APPLY="${APPLY:-1}"
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
FILTER="${FILTER:-$SCRIPT_DIR/filter.jq}"

umask 022
mkdir -p "$(dirname "$OUT")"

if [ -n "$PODS_JSON" ]; then
  input=$PODS_JSON
else
  input=$(mktemp)
  trap 'rm -f "$input"' EXIT
  kubectl get pods -n "$NAMESPACE" -o json > "$input"
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required to filter pod JSON to digests only" >&2
  exit 1
fi

jq --arg namespace "$NAMESPACE" -f "$FILTER" "$input" > "$OUT"

if [ "$APPLY" = "0" ] || [ "$APPLY" = "false" ]; then
  cat "$OUT"
  exit 0
fi

kubectl create configmap "$CM_NAME" \
  --namespace "$NAMESPACE" \
  --from-file=images.json="$OUT" \
  --dry-run=client -o yaml \
  | kubectl apply -f -
