#!/usr/bin/env bash
# Creates a lab CA and issues a Harbor server certificate valid 90 days.
set -euo pipefail

PKI="${LAB_PKI_DIR:-$HOME/.local/share/lab-pki}"
REPO_PKI="$(git rev-parse --show-toplevel)/pki"
mkdir -p "$PKI" "$REPO_PKI"
chmod 700 "$PKI"
cd "$PKI"

if [ ! -f ca.key ]; then
  openssl genrsa -out ca.key 4096
  openssl req -x509 -new -key ca.key -sha256 -days 365 -subj "/CN=lab-ca" -out ca.crt \
    -addext "basicConstraints=critical,CA:TRUE" \
    -addext "keyUsage=critical,keyCertSign,cRLSign"
fi

openssl genrsa -out harbor.key 3072
openssl req -new -key harbor.key -subj "/CN=harbor.lab.test" -out harbor.csr
cat > harbor.ext <<'EOF'
subjectAltName=DNS:harbor.lab.test,IP:192.168.150.20
basicConstraints=CA:FALSE
keyUsage=digitalSignature,keyEncipherment
extendedKeyUsage=serverAuth
EOF
openssl x509 -req -in harbor.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
  -out harbor.crt -days 90 -sha256 -extfile harbor.ext

cp ca.crt "$REPO_PKI/lab-ca.crt"
chmod 600 ./*.key
echo "CA public cert -> $REPO_PKI/lab-ca.crt (commit this)"
echo "Server cert/key -> $PKI (never commit)"
openssl x509 -in harbor.crt -noout -subject -issuer -dates -ext subjectAltName
