# Caddy Custom Build with Plugins

This repository automatically builds Docker images based on the **official Caddy image** with additional plugins compiled in.

## Included Plugins

- **netcup** - DNS provider for netcup
- **duckdns** - DNS provider for DuckDNS  
- **ddns** - Dynamic DNS updates
- **sablier** - Dynamic container management
- **defender** - Security/Rate limiting (via caddy-security)
- **coraza-waf** - Web Application Firewall
- **geoip-filter** - GeoIP-based filtering

## Automated Builds

### GitHub Actions

The repository contains three GitHub Actions:

1. **Build Caddy with Custom Plugins** (`build-caddy.yml`)
   - Runs daily to check for new Caddy versions
   - Can be triggered manually
   - Builds multi-platform images (amd64, arm64)
   - Performs security scans

2. **Update Plugin Dependencies** (`update-dependencies.yml`)
   - Runs weekly to check for plugin updates
   - Automatically creates pull requests for updates
   - Can be run manually

### Usage

#### Using the Docker Image

```bash
# Latest version
docker pull ghcr.io/mwitasse/caddy-custom-plugins/caddy-custom:latest

```

#### Docker Compose Example

```yaml
version: '3.8'
services:
  caddy:
    image: ghcr.io/mwitasse/caddy-custom-plugins/caddy-custom:latest
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile
      - caddy_data:/data
      - caddy_config:/config
    environment:
      - NETCUP_API_KEY=your_key
      - NETCUP_API_PASSWORD=your_password
      - DUCKDNS_TOKEN=your_token

volumes:
  caddy_data:
  caddy_config:
```

#### Manual Builds

To build a new image manually:

1. Go to "Actions" → "Build Caddy with Custom Plugins"
2. Click "Run workflow"
3. Optional: Specify a specific Caddy version
4. Optional: Enable "Force rebuild" to override existing images

## Configuration

### Caddyfile Examples

#### With netcup DNS
```
example.com {
    tls {
        dns netcup {
            api_key {env.NETCUP_API_KEY}
            api_password {env.NETCUP_API_PASSWORD}
            customer_number {env.NETCUP_CUSTOMER_NUMBER}
        }
    }
    reverse_proxy backend:8080
}
```

#### With DuckDNS
```
subdomain.duckdns.org {
    tls {
        dns duckdns {
            token {env.DUCKDNS_TOKEN}
        }
    }
    reverse_proxy backend:8080
}
```

#### With Sablier (Dynamic Scaling)
```
app.example.com {
    reverse_proxy sablier:8080 {
        dynamic docker {
            name myapp
            image nginx:alpine
        }
    }
}
```

#### With Coraza WAF
```
example.com {
    coraza_waf {
        directives `
            SecRuleEngine On
            SecRule ARGS "@detectSQLi" "id:1001,phase:2,block,msg:'SQL Injection Attack'"
        `
    }
    reverse_proxy backend:8080
}
```

#### With GeoIP Filtering
```
example.com {
    geoip {
        database_path /data/GeoLite2-Country.mmdb
        allow_countries DE AT CH
    }
    reverse_proxy backend:8080
}
```


## Monitoring and Updates

### Automatic Checks

- **Daily**: Check for new Caddy versions
- **Weekly**: Check for plugin updates
- **On Push**: Rebuild on Dockerfile changes

### Security Scans

Every build is automatically scanned with Trivy and results are uploaded to the GitHub Security tab.

### Build Status

Build status and available versions can be viewed in the repository's "Actions" section.

## Support

For issues:
1. Check the GitHub Actions logs
2. Create an issue with detailed error description
3. Review plugin documentation for configuration help

## Plugin Documentation

- [Caddy netcup DNS](https://github.com/caddy-dns/netcup)
- [Caddy DuckDNS](https://github.com/caddy-dns/duckdns)
- [Dynamic DNS](https://github.com/mholt/caddy-dynamicdns)
- [Sablier](https://github.com/acouvreur/sablier)  
- [Caddy Security](https://github.com/greenpau/caddy-security)
- [Coraza WAF](https://github.com/corazawaf/coraza-caddy)
- [MaxMind GeoLocation](https://github.com/porech/caddy-maxmind-geolocation)