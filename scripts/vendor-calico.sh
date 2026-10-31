#!/usr/bin/env bash
# Vendor the exact Calico manifests into the repo so a rebuild never depends on a GitHub download.
set -euo pipefail
V="${1:?usage: vendor-calico.sh vX.Y.Z [pod-cidr]}"
POD_CIDR="${2:-10.244.0.0/16}"
DIR="ansible/roles/control_plane/files/calico-$V"
BASE="https://raw.githubusercontent.com/projectcalico/calico/$V/manifests"
mkdir -p "$DIR"
curl -fsSL -o "$DIR/crds.yaml"              "$BASE/v3_projectcalico_org.yaml"
curl -fsSL -o "$DIR/tigera-operator.yaml"   "$BASE/tigera-operator.yaml"
curl -fsSL -o "$DIR/custom-resources.yaml"  "$BASE/custom-resources.yaml"

# The default pool is 192.168.0.0/16, which overlaps your lab network (192.168.150.0/24).
# Replace it with the cluster pod CIDR.
sed -i "s#cidr: 192.168.0.0/16#cidr: $POD_CIDR#" "$DIR/custom-resources.yaml"
grep -n "cidr:" "$DIR/custom-resources.yaml"
sha256sum "$DIR"/*.yaml | tee "$DIR/SHA256SUMS"
echo "Review the diff before committing. The operator needs broad RBAC and privileged pods; that is expected for a CNI."
