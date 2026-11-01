#!/usr/bin/env bash
set -euo pipefail
V="${1:-v2.15.4}"
DEST="${XDG_CACHE_HOME:-$HOME/.cache}/lab"; mkdir -p "$DEST"; cd "$DEST"
F="harbor-offline-installer-$V.tgz"
BASE="https://github.com/goharbor/harbor/releases/download/$V"


curl -fsSL -o "$F.sigstore.json" "$BASE/$F.sigstore.json"

cosign verify-blob \
  --bundle "$F.sigstore.json" \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  --certificate-identity-regexp '^https://github.com/goharbor/harbor/.github/workflows/publish_release.yml@refs/tags/v.*$' \
  "$F"   # prints "Verified OK" on success

sha256sum "$F" | tee "$F.sha256"
echo "Paste the sha256 into ansible/group_vars/registry/main.yml (harbor_installer_sha256)."
