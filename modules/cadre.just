# modules/cadre.just
# RSR: Internal Service Router

# Clone/Update the router
get-router:
    @echo ">>> [Cadre] Fetching Router Source..."
    # Assuming public or SSH access exists
    git clone https://github.com/hyperpolymath/cadre-router.git internal/cadre || (cd internal/cadre && git pull)

# Build the Router (Assuming standard RSR Rust/ReScript pattern)
build-router: get-router
    @echo ">>> [Cadre] Building Router..."
    # Detect if it's Rust (cargo) or Node/ReScript and build accordingly
    if [ -f "internal/cadre/Cargo.toml" ]; then \
        cd internal/cadre && cargo build --release; \
    else \
        cd internal/cadre && npm install && npm run build; \
    fi

# Run logic is handled by the main deploy pod
