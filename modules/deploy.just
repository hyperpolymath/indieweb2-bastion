# modules/deploy.just
# RSR Deployment: The "IndieWeb2 Pod"
# Orchestrates Bastion + Router + IPFS + MCPs in a single network namespace.

# Import dependencies (ensure builders exist)
import 'modules/container.just'
import 'modules/mcp.just'

# 1. STOP & CLEAN
# ---------------------------------------------------------
clean:
    @echo ">>> [Podman] Cleaning up old Pods..."
    podman pod stop indieweb2-pod || true
    podman pod rm indieweb2-pod || true
    podman rm -f bastion cadre-router ipfs-node mcp-git || true

# 2. DEPLOY (The Full Stack)
# ---------------------------------------------------------
deploy: clean build build-mcps
    @echo ">>> [Podman] Deploying IndieWeb2 Pod (Port 443)..."

    # A. Create the Pod (The Shared Network Bubble)
    #    We map Port 443 (TCP+UDP) here so all containers share it.
    podman pod create --name indieweb2-pod \
        --infra=true \
        -p 443:443/tcp \
        -p 443:443/udp

    # B. Start IPFS Sidecar (Internal: localhost:8080)
    #    Uses the official hardened image or your custom build.
    @echo "    + [Sidecar] IPFS Node"
    podman run -d --pod indieweb2-pod --name ipfs-node \
        -e IPFS_PROFILE=server \
        ipfs/kubo:latest

    # C. Start Cadre Router (Internal: localhost:3000)
    #    The "Brain" for internal service routing.
    @echo "    + [Sidecar] Cadre Router"
    # (Assuming you have pulled/built this as discussed)
    podman run -d --pod indieweb2-pod --name cadre-router \
        -v $(pwd)/internal/cadre/config:/app/config \
        indieweb2-cadre-router

    # D. Start MCP Sidecars (Internal: localhost:3001+)
    @echo "    + [Sidecar] MCP: Poly-Git"
    podman run -d --pod indieweb2-pod --name mcp-git mcp-poly-git

    # E. Start BASTION (The Gateway)
    #    This binds to the Pod's Port 443.
    #    It talks to the others via 'localhost'.
    @echo "    + [Gateway] Bastion"
    podman run -d --pod indieweb2-pod --name bastion \
        --cap-add CAP_NET_BIND_SERVICE \
        -v $(pwd)/certs:/app/certs:ro \
        indieweb2-bastion

    @echo ">>> [RSR] System Online: https://localhost"
