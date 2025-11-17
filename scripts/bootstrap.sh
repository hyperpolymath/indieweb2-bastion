#!/usr/bin/env bash
set -euo pipefail

echo "Checking required tools..."

# jq
if ! command -v jq >/dev/null; then
  sudo dnf install -y jq
fi

# capnp
if ! command -v capnp >/dev/null; then
  sudo dnf install -y capnproto
fi

# nickel
if ! command -v nickel >/dev/null; then
  echo "Nickel not in Fedora repos. Installing from source..."
  curl -L https://github.com/tweag/nickel/releases/latest/download/nickel-x86_64-unknown-linux-gnu.tar.gz \
    | tar xz -C /usr/local/bin
fi

# deno
if ! command -v deno >/dev/null; then
  echo "Installing Deno..."
  curl -fsSL https://deno.land/install.sh | sh
  export PATH="$HOME/.deno/bin:$PATH"
fi

echo "All tools checked."
