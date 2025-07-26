# Build arguments (global scope)
ARG CADDY_VERSION=2.10.0

# Builder stage
FROM golang:1.24-alpine AS builder

# Re-declare ARG for this stage
ARG CADDY_VERSION

# Install build dependencies
RUN apk add --no-cache git ca-certificates

# Set working directory
WORKDIR /build

# Initialize Go module
RUN go mod init caddy-custom

# Create main.go with all plugins
RUN cat > main.go << 'EOF'
package main

import (
    caddycmd "github.com/caddyserver/caddy/v2/cmd"

    // Standard Caddy modules
    _ "github.com/caddyserver/caddy/v2/modules/standard"

    // DNS Provider Plugins
    _ "github.com/caddy-dns/netcup"
    _ "github.com/caddy-dns/duckdns"

    // Dynamic DNS Plugin
    _ "github.com/mholt/caddy-dynamicdns"

    // Docker Proxy Plugin
    _ "github.com/lucaslorentz/caddy-docker-proxy/v2/plugin"

    // Sablier Plugin (Dynamic Container Management)
    _ "github.com/acouvreur/sablier/plugins/caddy"

    // Security/WAF Plugins
    _ "github.com/greenpau/caddy-security"
    _ "github.com/corazawaf/coraza-caddy/v2"

    // Geolocation Plugin
    _ "github.com/porech/caddy-maxmind-geolocation"
)

func main() {
    caddycmd.Main()
}
EOF

# Let Go resolve all dependencies automatically
RUN go mod tidy

# Build custom Caddy binary
RUN CGO_ENABLED=0 GOOS=linux go build \
    -a -ldflags="-s -w -X github.com/caddyserver/caddy/v2.CustomVersion=custom-plugins-v${CADDY_VERSION}" \
    -trimpath \
    -o caddy \
    .

# Verify the binary works
RUN ./caddy version

# Runtime stage - use official Caddy image as base  
ARG CADDY_VERSION
FROM caddy:${CADDY_VERSION}-alpine

# Copy custom Caddy binary over the official one
COPY --from=builder /build/caddy /usr/bin/caddy

# Verify the custom binary works and show loaded plugins
RUN caddy version && caddy list-modules --versions

# Labels for image metadata
LABEL org.opencontainers.image.title="Caddy with Custom Plugins" \
      org.opencontainers.image.description="Official Caddy ${CADDY_VERSION} image with netcup, duckdns, ddns, dockerproxy, sablier, defender, coraza-waf, and geoip-filter plugins" \
      org.opencontainers.image.vendor="Custom Build" \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.source="https://github.com/caddyserver/caddy" \
      caddy.version="${CADDY_VERSION}" \
      caddy.plugins="netcup,duckdns,ddns,dockerproxy,sablier,defender,coraza-waf,geoip-filter"

# The rest is inherited from the official Caddy image:
# - USER caddy  
# - EXPOSE 80 443 2019
# - VOLUME ["/config", "/data"]
# - WORKDIR /srv
# - CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]