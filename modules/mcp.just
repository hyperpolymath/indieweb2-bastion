cat << 'EOF' > modules/mcp.just
# --- MODEL CONTEXT PROTOCOLS (MCP) ---

# 1. Fetch all Poly-MCPs defined in config
fetch-mcps:
    @echo ">>> [MCP] Fetching Poly-MCPs..."
    # (Simple loop implementation for the 'baby pigeon' step)
    mkdir -p internal/mcps
    # Example for git-mcp (Repeat/Script for others)
    if [ ! -d "internal/mcps/poly-git" ]; then git clone https://github.com/hyperpolymath/poly-git-mcp internal/mcps/poly-git; fi

# 2. Build MCP Containers
# Assumes the Poly repos have a Containerfile, or applies a generic RSR wrapper
build-mcps: fetch-mcps
    @echo ">>> [MCP] Building Sidecars..."
    # Build Poly-Git
    podman build -t mcp-poly-git -f internal/mcps/poly-git/Containerfile internal/mcps/poly-git

# 3. Deploy Sidecars (Attached to the Main Pod)
# This is called by the main 'deploy' recipe
deploy-mcps:
    @echo ">>> [MCP] Starting Sidecars in Pod..."
    # Poly-Git running on localhost:3001 inside the pod
    podman run -d --pod indieweb2-pod --name mcp-git mcp-poly-git
EOF
