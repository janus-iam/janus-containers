#!/bin/sh
# Write a JSON list of running containers with image identity only.
# Does not emit Env, mounts, command, or other container spec.
set -eu

OUT="${OUT:-/out/images.json}"
TMP="${OUT}.tmp"

json_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g; s/	/\\t/g'
}

umask 022
mkdir -p "$(dirname "$OUT")"

{
  printf '{\n  "generated_by": "janus-containers/examples/vps-digest-status",\n  "containers": [\n'
  first=1
  # shellcheck disable=SC2046
  for cid in $(docker ps -q); do
    name=$(docker inspect -f '{{.Name}}' "$cid")
    name=${name#/}
    image=$(docker inspect -f '{{.Config.Image}}' "$cid")
    image_id=$(docker inspect -f '{{.Image}}' "$cid")
    service=$(docker inspect -f '{{index .Config.Labels "com.docker.compose.service"}}' "$cid")
    digests=$(docker image inspect -f '{{range $i, $d := .RepoDigests}}{{if $i}} {{end}}{{$d}}{{end}}' "$image_id" 2>/dev/null || true)

    if [ "$first" -eq 1 ]; then
      first=0
    else
      printf ',\n'
    fi

    printf '    {\n'
    printf '      "name": "%s",\n' "$(json_escape "$name")"
    if [ -n "$service" ]; then
      printf '      "compose_service": "%s",\n' "$(json_escape "$service")"
    else
      printf '      "compose_service": null,\n'
    fi
    printf '      "image": "%s",\n' "$(json_escape "$image")"
    printf '      "image_id": "%s",\n' "$(json_escape "$image_id")"
    printf '      "repo_digests": ['
    dfirst=1
    for d in $digests; do
      if [ "$dfirst" -eq 1 ]; then
        dfirst=0
      else
        printf ', '
      fi
      printf '"%s"' "$(json_escape "$d")"
    done
    printf ']\n    }'
  done
  printf '\n  ]\n}\n'
} > "$TMP"

mv -f "$TMP" "$OUT"
