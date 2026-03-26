# Adding a Service

Every new service requires the following integration points.

---

## 1. `services/<name>/compose.yml`

- Set `name: <service-name>` explicitly
- Use `proxy_net` as an external network
- No `ports:` — all traffic goes via Traefik
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

---

## 2. `config/traefik/dynamic/<name>.yml`

Traefik watches `config/traefik/dynamic/` with `watch: true`. Drop a file there and routing is live immediately — no Traefik restart needed.

Use the `@file` suffix for middlewares defined in `dynamic.yml` (required in Traefik v3 for cross-file references):

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
        - authelia@file
        - secure-headers@file
      service: my-service-svc

  services:
    my-service-svc:
      loadBalancer:
        servers:
          - url: http://my-service:8080
```

Use `authelia@file` for any service without its own login. Skip it only if the service has a proper built-in authentication mechanism.

---

## 3. `compose.yml` — step-ca `extra_hosts`

step-ca must resolve each service's hostname on port 443 to complete the TLS-ALPN-01 ACME challenge. Add each new service to step-ca's `extra_hosts` in the core `compose.yml`:

```yaml
    extra_hosts:
      - "my-service.app.home.arpa:host-gateway"
```

Without this, certificate issuance fails with "The server could not connect to validation target".

---

## 4. `compose.yml` — Pi-hole DNS entry

Add a DNS A-record to `FTLCONF_dns_hosts` in the core `compose.yml`:

```yaml
      FTLCONF_dns_hosts: |-
        ${SERVER_LOCAL_IP:-192.168.0.10} pihole.app.home.arpa
        ${SERVER_LOCAL_IP:-192.168.0.10} traefik.app.home.arpa
        ${SERVER_LOCAL_IP:-192.168.0.10} my-service.app.home.arpa
```

Restart Pi-hole to apply:

```bash
docker compose up -d pihole
```

---

## 5. `services/<name>/.env.example`

Document all service-specific environment variables with defaults and comments. Operators copy this to `.env` before first start.

---

## Checklist

- [ ] No `ports:` — only `expose:` for internal Docker networking
- [ ] Image tag pinned to a specific version
- [ ] `proxy_net: external: true`
- [ ] `secure-headers@file` middleware in Traefik config
- [ ] `authelia@file` middleware added (unless service has built-in auth)
- [ ] DNS entry added to `FTLCONF_dns_hosts` in core `compose.yml`
- [ ] `extra_hosts` entry added to step-ca in `compose.yml`
- [ ] `.env.example` present if the service uses environment variables; `.env` is gitignored

> **CI enforcement:** The Services workflow (`services.yml`) automatically checks that `ports:` is absent and all networks are `external: true`. The CI workflow (`ci.yml`) checks that every Traefik route file includes `authelia@file`. Violations block merges.

---

## Removing a Service

1. Stop and remove the containers:
   ```bash
   docker compose -f services/<name>/compose.yml down -v
   ```
2. Remove `config/traefik/dynamic/<name>.yml` — Traefik picks up the change immediately.
3. Remove the `extra_hosts` entry from `stepca` in core `compose.yml`.
4. Remove the DNS entry from `FTLCONF_dns_hosts`, then restart Pi-hole:
   ```bash
   docker compose up -d pihole
   ```