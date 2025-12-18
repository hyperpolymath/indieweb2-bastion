#!/bin/bash
set -e

# RSR CRYPTO LOOM
# Algorithm: Ed448 (Goldilocks) > Ed25519
# Hash: SHA-512

CERT_DIR="certs"
mkdir -p "$CERT_DIR"

echo ">>> [Loom] Spinning Cryptographic Material..."

# Detect Algorithm
if openssl list -public-key-algorithms | grep -q "ed448"; then
    ALGO="ed448"
    echo "    - Algorithm: Ed448 (Goldilocks) [ACTIVE]"
else
    ALGO="ed25519"
    echo "    - Algorithm: Ed448 unavailable, using Ed25519 [FALLBACK]"
fi

# 1. CA Root (The Trust Anchor)
openssl genpkey -algorithm $ALGO -out "$CERT_DIR/ca.key"
openssl req -x509 -new -key "$CERT_DIR/ca.key" \
    -sha512 -days 3650 \
    -subj "/C=UK/O=IndieWeb2/OU=Rhodium/CN=IndieWeb2 Root CA" \
    -out "$CERT_DIR/ca.crt"

# 2. Bastion Key (The Server)
openssl genpkey -algorithm $ALGO -out "$CERT_DIR/privkey.pem"

# 3. CSR Config (For SANs)
cat <<CONF > "$CERT_DIR/openssl.cnf"
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no
[req_distinguished_name]
C = UK
O = IndieWeb2
OU = Bastion
CN = localhost
[v3_req]
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth, clientAuth
subjectAltName = @alt_names
[alt_names]
DNS.1 = localhost
IP.1 = 127.0.0.1
IP.2 = ::1
CONF

# 4. Sign Bastion Cert
openssl req -new -key "$CERT_DIR/privkey.pem" \
    -config "$CERT_DIR/openssl.cnf" \
    -out "$CERT_DIR/bastion.csr"

openssl x509 -req -in "$CERT_DIR/bastion.csr" \
    -CA "$CERT_DIR/ca.crt" -CAkey "$CERT_DIR/ca.key" -CAcreateserial \
    -sha512 -days 365 \
    -extensions v3_req -extfile "$CERT_DIR/openssl.cnf" \
    -out "$CERT_DIR/fullchain.pem"

echo ">>> [Loom] Complete. Import 'certs/ca.crt' to your browser trust store."
