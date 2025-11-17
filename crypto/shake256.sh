#!/usr/bin/env bash
set -euo pipefail
FILE="$1"
if [ -z "$FILE" ]; then
  echo "Usage: shake256.sh <file>"
  exit 2
fi
if command -v openssl >/dev/null; then
  openssl dgst -shake256 "$FILE"
else
  echo "openssl not available; stub hash"
fi
