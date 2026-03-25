# Optional Services

Optional services live here as independent Docker Compose projects. They can be started and stopped without touching the core stack.

## Prerequisites

The core stack must be running before starting any optional service:

```bash
docker compose --env-file .env up -d
```

## Starting and stopping a service

```bash
# Start
docker compose -f services/bentopdf/compose.yml up -d

# Stop
docker compose -f services/bentopdf/compose.yml down
```

---

## Adding a new service

Every new service requires exactly four integration points:

### 1. `services/<name>/compose.yml`

- Set `name: <service-name>` explicitly
- Use `proxy_net` as an external network (defined in core `compose.yml`)
- No published `ports:` — all traffic goes via Traefik
- Pin the image to a specific version tag (no `:latest`)
- Delegate auth to Traefik unless the service has its own login

```yaml
name: my-service

services:
  my-service:
    image: vendor/my-service:1.2.3
    container_name: my-service
    networks:
      - proxy_net
    expose:
      - "8080"
    restart: unless-stopped

networks:
  proxy_net:
    external: true
```

### 2. `config/traefik/dynamic/<name>.yml`

Traefik watches the entire `config/traefik/dynamic/` directory (`watch: true`). Drop a file there and routing is live immediately — no Traefik restart needed.

When referencing middlewares defined in `dynamic.yml` (e.g. `traefik-auth`, `secure-headers`), use the `@file` suffix — required in Traefik v3 for cross-file references:

```yaml
http:
  routers:
    my-service:
      rule: Host(`my-service.app.home.arpa`)
      entryPoints:
        - websecure
      tls:
        certResolver: stepca
      middlewares:
        - traefik-auth@file    # delegates auth to BasicAuth (usersfile)
        - secure-headers@file
      service: my-service-svc

  services:
    my-service-svc:
      loadBalancer:
        servers:
          - url: http://my-service:8080
```

Use `traefik-auth@file` for any service without its own login. Skip it only if the service has a proper built-in authentication mechanism.

### 3. `compose.yml` — step-ca `extra_hosts`

Step-ca must be able to resolve and reach each service's hostname on port 443 to complete the TLS-ALPN-01 ACME challenge. It connects back via `host-gateway` (the Docker host), so every service that needs a TLS cert must be added to step-ca's `extra_hosts` in the **core** `compose.yml`:

```yaml
    extra_hosts:
      - "my-service.app.home.arpa:host-gateway"
```

Without this entry, certificate issuance will fail with "The server could not connect to validation target".

### 4. `compose.yml` — Pi-hole DNS entry

Add a DNS A-record to `FTLCONF_dns_hosts` in the core `compose.yml` so `*.app.home.arpa` resolves to the server:

```yaml
      FTLCONF_dns_hosts: |-
        ${SERVER_LOCAL_IP:-192.168.0.10} pihole.app.home.arpa
        ${SERVER_LOCAL_IP:-192.168.0.10} traefik.app.home.arpa
        ${SERVER_LOCAL_IP:-192.168.0.10} my-service.app.home.arpa
```

After editing, restart Pi-hole to pick up the change:

```bash
docker compose up -d pihole
```

### 5. `services/<name>/.env.example`

Document all service-specific environment variables with defaults and comments. Operators copy this to `.env` before first start.

---

## Security checklist

- [ ] No `ports:` published to the host — only `expose:` for internal Docker networking
- [ ] Image tag pinned to a specific version
- [ ] `proxy_net: external: true`
- [ ] Traefik routing uses `secure-headers@file` middleware
- [ ] If no built-in login: `traefik-auth@file` middleware added
- [ ] DNS entry added to `FTLCONF_dns_hosts` in core `compose.yml`
- [ ] `extra_hosts` entry added to step-ca in `compose.yml` (required for TLS cert issuance)
- [ ] `.env.example` present and committed; `.env` is gitignored

## Removing a service

To remove an optional service completely:

1. Stop and remove the containers:
   ```bash
   docker compose -f services/<name>/compose.yml down -v
   ```
2. Remove `config/traefik/dynamic/<name>.yml` — Traefik picks up the change immediately, no restart needed.
3. Remove the `extra_hosts` entry from `stepca` in core `compose.yml`.
4. Remove the DNS entry from `FTLCONF_dns_hosts` in core `compose.yml`, then restart Pi-hole:
   ```bash
   docker compose up -d pihole
   ```

---

## Available services

| Service | URL | Purpose |
|---------|-----|---------|
| [BentoPDF](bentopdf/) | `https://bentopdf.app.home.arpa` | PDF tools |