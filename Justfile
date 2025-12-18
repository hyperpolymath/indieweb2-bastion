# ... (previous lines)

# --- DEPLOY ---
deploy: build
    @echo ">>> [Podman] Deploying Bastion (IPv4/IPv6 + QUIC)..."
    # Map TCP and UDP. 
    # Mount certs (Assuming they exist in ./certs on host, otherwise generate self-signed)
    podman run -d --name bastion --restart always \
        -p 443:443/tcp \
        -p 443:443/udp \
        -v $(pwd)/certs:/app/certs:ro \
        indieweb2-bastion

# ... (rest of file)
