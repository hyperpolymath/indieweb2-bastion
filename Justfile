# IndieWeb2 Bastion — Superoptimised Justfile
set shell := ["bash", "-cu"]

# Paths
TMP_DIR := ".tmp"
POLICY_DIR := "policy/curps"
POLICY_NCL := "{{POLICY_DIR}}/policy.ncl"
POLICY_JSON := "{{TMP_DIR}}/policy.json"

RESCRIPT_OUT_CLI := "lib/js/src/PolicyGateCLI.js"
DENO_SIGN := "policy/runner/crypto/sign_policy.js"
DENO_RUNNER := "policy/runner/policy/run.js"

# ---------------------------
# Bootstrap (dirs + tools)
# ---------------------------
bootstrap:
  mkdir -p {{TMP_DIR}} policy/runner/crypto policy/runner/policy sbom logging products/pwa/build
  if ! command -v jq >/dev/null; then sudo dnf install -y jq; fi
  if ! command -v capnp >/dev/null; then sudo dnf install -y capnproto; fi
  if ! command -v nickel >/dev/null; then \
    echo "Installing Nickel..."; \
    curl -L https://github.com/tweag/nickel/releases/latest/download/nickel-x86_64-unknown-linux-gnu.tar.gz \
      | tar xz -C /usr/local/bin; \
  fi
  if ! command -v deno >/dev/null; then \
    echo "Installing Deno..."; \
    curl -fsSL https://deno.land/install.sh | sh; \
    export PATH="$$HOME/.deno/bin:$$PATH"; \
  fi

# ---------------------------
# Validation
# ---------------------------
validate: bootstrap
  nickel export {{POLICY_NCL}} > {{POLICY_JSON}}
  capnp compile -oc++ surrealdb/provenance.capnp
  surreal validate surrealdb/schema.surql

validate-eval: bootstrap
  nickel eval {{POLICY_NCL}} > /dev/null

validate-pretty: bootstrap
  nickel export {{POLICY_NCL}} | jq . > {{TMP_DIR}}/policy.pretty.json

# ---------------------------
# ReScript policy gate
# ---------------------------
rescript-build:
  npx rescript build

policy-gate: validate rescript-build
  node {{RESCRIPT_OUT_CLI}} {{POLICY_JSON}}

# ---------------------------
# Deno signing & publishing
# ---------------------------
sign-policy: validate
  deno run --allow-read --allow-write --unstable {{DENO_SIGN}} {{POLICY_JSON}} {{TMP_DIR}}/policy.sig

verify-publish:
  deno run --allow-read --allow-run --allow-write --unstable {{DENO_RUNNER}} {{POLICY_JSON}} {{TMP_DIR}}/policy.sig.json

# ---------------------------
# GUI / PWA dev server with port check
# ---------------------------
gui-dev: bootstrap
  PORT=8443; \
  if ss -ltn | grep -q ":$$PORT "; then \
    echo "Port $$PORT in use. Trying 8080..."; PORT=8080; \
  fi; \
  echo "Starting static server on port $$PORT"; \
  deno run --allow-read --allow-net scripts/static_serve.js products/pwa/public $$PORT

# ---------------------------
# Full pipeline
# ---------------------------
all: validate policy-gate sign-policy verify-publish gui-dev
