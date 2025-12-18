# RSR: Use Wolfi base for SBOM/Security compliance
FROM cgr.dev/chainguard/wolfi-base:latest AS builder

# Install build deps
RUN apk add --no-cache build-base deno git

WORKDIR /app
COPY . .

# RSR: Build ReScript/Deno assets
RUN deno task build

# Runtime Stage
FROM cgr.dev/chainguard/wolfi-base:latest

# Install runtime deps (clean, minimal)
RUN apk add --no-cache deno ca-certificates

WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/config ./config

# Drop to non-root user
USER nonroot

# Expose standard Bastion port
EXPOSE 8443

# Start via Deno (secure runtime)
CMD ["deno", "run", "--allow-net", "--allow-read", "dist/main.js"]
