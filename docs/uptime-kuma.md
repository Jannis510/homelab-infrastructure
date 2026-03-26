# Uptime Kuma

[Uptime Kuma](https://github.com/louislam/uptime-kuma) is a self-hosted monitoring tool for tracking service availability and response times.

It is an optional service and runs independently from the core stack.

---

## URL

```
https://uptime-kuma.app.home.arpa
```

Access is protected by Authelia (SSO, same session as all other services).

---

## Starting the Service

Requires the core stack to be running first:

```bash
# Start core stack
docker compose up -d

# Start Uptime Kuma
docker compose -f services/uptime-kuma/compose.yml up -d
```

Stop:

```bash
docker compose -f services/uptime-kuma/compose.yml down
```

---

## Initial Setup (first start only)

On first start, Uptime Kuma shows a setup wizard that cannot be skipped via environment variables (not implemented in v2). It must be completed once manually:

1. Open Uptime Kuma directly in the browser
2. Select language and confirm SQLite as the database (no further configuration needed)
3. Create an admin account
4. Done — state is persisted in the Docker volume and the wizard will not appear again

---

## Disabling Internal Auth

Since Authelia handles authentication, Uptime Kuma's own login screen should be disabled to avoid a double login:

**Settings → Advanced → Disable Auth**

This setting is stored in the volume and persists across container restarts.

> **Note:** There is no environment variable to disable auth in Uptime Kuma v2 — it must be set via the UI.

---

## Monitors

### Adding a Monitor

1. Click **Add New Monitor**
2. Set the monitor type (see table below)
3. Fill in hostname/URL and port as listed
4. Set a display name
5. Save

### Monitor List

| Service      | Monitor Type | Hostname / URL                              | Port |
|--------------|-------------|----------------------------------------------|------|
| Pi-hole      | TCP Port    | `pihole`                                     | `53` |
| Unbound      | TCP Port    | `unbound`                                    | `5335` |
| Traefik      | HTTP(s)     | `https://traefik.app.home.arpa/ping`         | —    |
| Authelia     | HTTP(s)     | `http://authelia:9091/api/health`            | —    |
| Step-CA      | HTTP(s)     | `https://stepca:9000/health`                 | —    |
| Netdata      | HTTP(s)     | `http://netdata:19999/api/v1/info`           | —    |
| Homepage     | HTTP(s)     | `http://homepage:3000/`                      | —    |
| BentoPDF     | HTTP(s)     | `http://bentopdf:8080/`                      | —    |
| ConvertX     | HTTP(s)     | `http://convertx:3000/`                      | —    |

> **Note:** TCP Port monitors only check if the port is reachable — no HTTP status is evaluated.
> HTTP(s) monitors expect a 2xx status code by default.

### Accepted Status Codes

All listed HTTP(s) endpoints return `200` — no changes needed.

---

## Notes

- SQLite is used as the database — no additional configuration needed
- After initial setup, no further manual intervention is required
- Monitors and settings are persisted in the `uptime-kuma` Docker volume