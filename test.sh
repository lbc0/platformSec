#!/usr/bin/env bash
# Prints the attribute names the installed provider really exposes, so you can compare with main.tf.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)/terraform"
terraform init -input=false >/dev/null
terraform providers schema -json > /tmp/libvirt-schema.json

R='.provider_schemas | to_entries[0].value.resource_schemas'
for r in libvirt_pool libvirt_network libvirt_volume libvirt_cloudinit_disk libvirt_domain; do
  echo "== $r"
  jq -r "$R[\"$r\"].block.attributes | keys | join(\", \")" /tmp/libvirt-schema.json
done
echo "== libvirt_domain.devices.disks[*] attributes"
jq -r "$R[\"libvirt_domain\"].block.attributes.devices.nested_type.attributes.disks.nested_type.attributes | keys | join(\", \")" /tmp/libvirt-schema.json
echo "== libvirt_volume.backing_store attributes"
jq -r "$R[\"libvirt_volume\"].block.attributes.backing_store.nested_type.attributes | keys | join(\", \")" /tmp/libvirt-schema.json
