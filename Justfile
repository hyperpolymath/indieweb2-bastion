set shell := ["bash", "-c"]

# Default recipe
default: list

# List all available recipes
list:
    @just --list

# ---------------------------------------------------------
# 1. BOOTSTRAP & PRE-FLIGHT
# ---------------------------------------------------------

# Install dependencies (RSR: Deno, Nickel, Podman)
bootstrap:
    @echo ">>> [RSR] Bootstrapping Environment..."
    @# Check for Deno
    @if ! command -v deno &> /dev/null; then echo "Installing Deno..."; curl -fsSL https://deno.land/x/install/install.sh | sh; fi
    @# Check for Nickel
    @if ! command -v nickel &> /dev/null; then echo "Installing Nickel..."; cargo install nickel-lang-cli; fi
    @# Check for Just
    @if ! command -v just &> /dev/null; then echo "Installing Just..."; cargo install just; fi
    @echo ">>> Bootstrap complete."

# Verify Nickel policies
verify-policy:
    @echo ">>> [RSR] Verifying Nickel Contracts..."
    nickel export config/main.ncl > /dev/null
    @echo ">>> Policies Valid."

# ---------------------------------------------------------
# 2. BUILD
# ---------------------------------------------------------

# Build the Wolfi-based Bastion container
build: verify-policy
    @echo ">>> [Podman] Building Bastion (Wolfi Base)..."
    podman build -t indieweb2-bastion -f container/Containerfile .

# Generate shell installation vectors
gen-scripts:
    @echo ">>> Generating multi-shell bootstrap scripts..."
    # This would link to a script generator, ensuring consistency
    deno run --allow-write scripts/generate_shells.ts

# ---------------------------------------------------------
# 3. DEPLOY
# ---------------------------------------------------------

# Deploy via Podman (Rootless)
deploy: build
    @echo ">>> [Podman] Deploying Bastion..."
    podman run -d --name bastion --restart always -p 8443:8443 indieweb2-bastion

# Stop and remove the deployment
clean:
    podman stop bastion || true
    podman rm bastion || true

# ---------------------------------------------------------
# 4. RELEASE
# ---------------------------------------------------------

# Tag and Sign the release
release version:
    @echo ">>> Release v{{version}}"
    git tag -s v{{version}} -m "RSR Release v{{version}}"
    git push origin v{{version}}
