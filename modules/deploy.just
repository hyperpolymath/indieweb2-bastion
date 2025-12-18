# modules/deploy.just (Updated)

deploy-pod: build build-router
    @echo ">>> [Podman] Deploying Indieweb2 Pod..."
    
    # 1. Create the Pod (Shared Namespace)
    podman pod create --name indieweb2-pod \
        -p 443:443/tcp -p 443:443/udp \
        --infra=true

    # 2. Start Cadre Router (Listening on localhost:3000 inside pod)
    podman run -d --pod indieweb2-pod --name cadre-router \
        -v $(pwd)/internal/cadre/config:/app/config \
        indieweb2-cadre-router

    # 3. Start Bastion (Listening on 443, proxying to localhost:3000)
    podman run -d --pod indieweb2-pod --name bastion \
        -v $(pwd)/certs:/app/certs:ro \
        indieweb2-bastion
