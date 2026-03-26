# Monitoring

Three optional monitoring services — availability tracking, system metrics, and container logs — bundled in a single Compose stack.

All three run independently from the core stack and share one socket proxy.

---

## Starting and Stopping

Requires the core stack to be running first:

```bash
# Start core stack
docker compose up -d

# Start monitoring stack
docker compose -f services/monitoring/compose.yml up -d
```

Stop:

```bash
docker compose -f services/monitoring/compose.yml down
```

---

## Uptime Kuma

[Uptime Kuma](https://github.com/louislam/uptime-kuma) tracks service availability and response times.

**URL:** `https://uptime-kuma.app.home.arpa`

Access is protected by Authelia (SSO, same session as all other services).

### Initial Setup (first start only)

On first start, Uptime Kuma shows a setup wizard that cannot be skipped via environment variables (not implemented in v2). It must be completed once manually:

1. Open Uptime Kuma directly in the browser
2. Select language and confirm SQLite as the database (no further configuration needed)
3. Create an admin account
4. Done — state is persisted in the Docker volume and the wizard will not appear again

### Disabling Internal Auth

Since Authelia handles authentication, Uptime Kuma's own login screen should be disabled to avoid a double login:

**Settings → Advanced → Disable Auth**

This setting is stored in the volume and persists across container restarts.

> **Note:** There is no environment variable to disable auth in Uptime Kuma v2 — it must be set via the UI.

### Monitors

#### Adding a Monitor

1. Click **Add New Monitor**
2. Set the monitor type (see table below)
3. Fill in hostname/URL and port as listed
4. Set a display name
5. Save

#### Monitor List

| Service      | Monitor Type | Hostname / URL                              | Port |
|--------------|-------------|----------------------------------------------|------|
| Pi-hole      | TCP Port    | `pihole`                                     | `53` |
| Unbound      | TCP Port    | `unbound`                                    | `5335` |
| Traefik      | HTTP(s)     | `https://traefik.app.home.arpa/ping`         | —    |
| Authelia     | HTTP(s)     | `http://authelia:9091/api/health`            | —    |
| Step-CA      | HTTP(s)     | `https://stepca:9000/health`                 | —    |
| Glances      | HTTP(s)     | `http://glances:61208/api/4/status`          | —    |
| Dozzle       | HTTP(s)     | `http://dozzle:8080/healthcheck`             | —    |
| Homepage     | HTTP(s)     | `http://homepage:3000/`                      | —    |
| BentoPDF     | HTTP(s)     | `http://bentopdf:8080/`                      | —    |
| ConvertX     | HTTP(s)     | `http://convertx:3000/`                      | —    |

> **Note:** TCP Port monitors only check if the port is reachable — no HTTP status is evaluated.
> HTTP(s) monitors expect a 2xx status code by default.

### Notes

- SQLite is used as the database — no additional configuration needed
- After initial setup, no further manual intervention is required
- Monitors and settings are persisted in the `uptime-kuma` Docker volume

---

## Glances

[Glances](https://github.com/nicolargo/glances) provides real-time system metrics: CPU, memory, disk, network, and running containers.

**URL:** `https://glances.app.home.arpa`

Access is protected by Authelia (SSO, same session as all other services).

### Initial Setup

No initial setup required — Glances starts fully configured.

### Architecture

Glances accesses Docker container information through the shared `monitoring-socket-proxy` sidecar instead of mounting the Docker socket directly. See [Security → Docker Socket Proxy](security.md#docker-socket-proxy) for details.

### Notes

- Glances runs with `pid: host` to read host process information
- Container metrics are read-only via the socket proxy
- No persistent volume — metrics are live only

---

## Dozzle

[Dozzle](https://github.com/amir20/dozzle) provides a real-time log viewer for all running Docker containers.

**URL:** `https://dozzle.app.home.arpa`

Access is protected by Authelia (SSO, same session as all other services).

### Initial Setup

No initial setup required — Dozzle starts fully configured.

### Architecture

Dozzle reads container logs and events through the shared `monitoring-socket-proxy` sidecar. Only `CONTAINERS` and `EVENTS` permissions are granted — no write access, no image or volume API access. See [Security → Docker Socket Proxy](security.md#docker-socket-proxy) for details.

### Notes

- No persistent volume — logs are streamed live from Docker
- All containers visible in Dozzle are also visible to Authelia-authenticated users; no per-container access control