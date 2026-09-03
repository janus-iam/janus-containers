test-transparency:
    sh examples/k8s-digest-publisher/test.sh
    sh examples/vps-digest-status/test.sh

check-conf:
    bunx renovate -- renovate-config-validator

dry-run:
    bunx renovate --platform=local --dry-run
