FROM golang:1.21-alpine AS builder

# Build arguments
ARG CADDY_VERSION=v2.8.4

# Install build dependencies
RUN apk add --no-cache git ca-certificates

# Set working directory
WORKDIR /build

# Initialize Go module for custom build
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

# Get Caddy core and plugins
RUN go get github.com/caddyserver/caddy/v2@${CADDY_VERSION}
RUN go get github.com/caddy-dns/netcup@latest
RUN go get github.com/caddy-dns/duckdns@latest
RUN go get github.com/mholt/caddy-dynamicdns@latest
RUN go get github.com/lucaslorentz/caddy-docker-proxy/v2@latest
RUN go get github.com/acouvreur/sablier@latest
RUN go get github.com/greenpau/caddy-security@latest
RUN go get github.com/corazawaf/coraza-caddy/v2@latest
RUN go get github.com/porech/caddy-maxmind-geolocation@latest

# Tidy dependencies
RUN go mod tidy

# Build custom Caddy
RUN CGO_ENABLED=0 GOOS=linux GOARCH=${TARGETARCH:-amd64} go build \
    -a -ldflags="-s -w -X github.com/caddyserver/caddy/v2.CustomVersion=custom-plugins" \
    -trimpath \
    -o caddy \
    .

# Runtime stage - use official Caddy image as base
FROM caddy:${CADDY_VERSION}-alpine

# Copy custom Caddy binary over the official one
COPY --from=builder /build/caddy /usr/bin/caddy

# Verify the binary works and show loaded plugins
RUN caddy version && caddy list-modules

# Labels for image metadata
LABEL org.opencontainers.image.title="Caddy with Custom Plugins" \
      org.opencontainers.image.description="Official Caddy image with netcup, duckdns, ddns, dockerproxy, sablier, defender, coraza-waf, and geoip-filter plugins" \
      org.opencontainers.image.vendor="Custom Build" \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.source="https://github.com/caddyserver/caddy" \
      caddy.plugins="netcup,duckdns,ddns,dockerproxy,sablier,defender,coraza-waf,geoip-filter"

# The rest is inherited from the official Caddy image:
# - USER caddy
# - EXPOSE 80 443 2019
# - VOLUME ["/config", "/data"]
# - WORKDIR /srv
# - CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]