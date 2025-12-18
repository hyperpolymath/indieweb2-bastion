set shell := ["bash", "-c"]

# Default recipe
default: list

# List all available recipes
list:
    @just --list

# ---------------------------------------------------------
# 1. BOOTSTRAP & PRE-FLIGHT
# ---------------------------------------------------------

# Install dependencies (RSR: Deno, Nickel, Podman, ReScript)
bootstrap:
    @echo ">>> [RSR] Bootstrapping Environment..."
    @if ! command -v deno &> /dev/null; then echo "Installing Deno..."; curl -fsSL https://deno.land/x/install/install.sh | sh; fi
    @if ! command -v nickel &> /dev/null; then echo "Installing Nickel..."; cargo install nickel-lang-cli; fi
    @if ! command -v rescript &> /dev/null; then echo "Installing ReScript..."; npm install -g rescript; fi
    @echo ">>> Bootstrap complete."

# Verify Nickel policies
verify-policy:
    @echo ">>> [RSR] Verifying Nickel Contracts..."
    nickel export config/main.ncl > /dev/null
    @echo ">>> Policies Valid."

# ---------------------------------------------------------
# 2. MAINTENANCE (Python/Salt)
# ---------------------------------------------------------

# Run the Python SaltStack bot for local self-healing
robot:
    @echo ">>> [Robot] Awakening..."
    python3 maintenance/robot.py

# ---------------------------------------------------------
# 3. BUILD & GENERATE (ReScript)
# ---------------------------------------------------------

# Compile ReScript sources (No TS allowed)
compile:
    @echo ">>> [ReScript] Compiling..."
    rescript build -with-deps

# Generate shell vectors using the compiled ReScript artifact
gen-scripts: compile
    @echo ">>> Running Shell Generator..."
    # strict usage of compiled JS artifact via Deno
    deno run --allow-read --allow-write --allow-env src/scripts/GenerateShells.bs.js

# Build the Wolfi-based Bastion container
build: verify-policy robot gen-scripts
    @echo ">>> [Podman] Building Bastion (Wolfi Base)..."
    podman build -t indieweb2-bastion -f container/Containerfile .

# ---------------------------------------------------------
# 4. DEPLOY
# ---------------------------------------------------------

deploy: build
    @echo ">>> [Podman] Deploying Bastion..."
    # UPDATED: Mapping Host 443 -> Container 443
    # Note: If running rootless, you may need to use a high port on the host (e.g. -p 8443:443) 
    # or ensure sysctl net.ipv4.ip_unprivileged_port_start=0 is set.
    podman run -d --name bastion --restart always -p 443:443 indieweb2-bastion

# Stop and remove the deployment
clean:
    podman stop bastion || true
    podman rm bastion || true

# ---------------------------------------------------------
# 5. RELEASE
# ---------------------------------------------------------

# Tag and Sign the release
release version:
    @echo ">>> Release v{{version}}"
    git tag -s v{{version}} -m "RSR Release v{{version}}"
    git push origin v{{version}}
