# Security

## Exposure Surface

By design, the host exposes only:

* `53/tcp`, `53/udp` → DNS (Pi-hole)
* `80/tcp`, `443/tcp` → HTTPS ingress (Traefik)

No other containers are published to the host network. All administrative interfaces are accessible only through HTTPS behind Traefik.

Assumptions:
- No router port forwarding is configured
- Host firewall rules block unsolicited WAN traffic
- Ports are not rebound to public interfaces

---

## Traefik Without Docker Socket

Traefik runs with the file provider and does not require Docker socket access.

Consequence: compromise of Traefik does not grant direct control over the Docker host.

Operational trade-off: no automatic container discovery via labels — routes must be added explicitly in `config/traefik/dynamic/*.yml`.

---

## Docker Socket Proxy

Services that need read-only Docker API access (Glances for container metrics, Dozzle for container logs) do not mount the Docker socket directly. Instead, a shared `tecnativa/docker-socket-proxy` sidecar in the monitoring stack exposes only the specific API endpoints required.

The sidecar runs in an isolated internal network (`socket_proxy_net`) with no external connectivity. The primary service container connects only to this internal network for Docker API calls and to `proxy_net` for Traefik routing — it never touches the Docker socket itself.

This limits the blast radius: a compromised service container cannot issue arbitrary Docker API calls or escalate to host control via the socket.

---

## Internal PKI and Trust

TLS certificates are issued by an internal `step-ca` instance via ACME.
`step-ca` is isolated in `pki_net` and reachable only by `traefik` and the one-shot `stepca-export` job.

* No browser warnings from ad-hoc self-signed certificates
* Full control over the trust chain
* No dependency on public certificate authorities

**Treat as sensitive:**
- `config/stepca/password.txt`
- CA keys and exported root artifacts
- Backups of CA material (encrypt and store offline)

If CA private material is compromised: perform full CA rotation and re-enroll trust on all clients.

---

## Network Segmentation

| Network | Services |
|---------|----------|
| `dns_net` | `pihole`, `unbound` |
| `proxy_net` | `traefik`, `pihole`, optional services |
| `pki_net` | `stepca`, `stepca-export`, `traefik` |
| `socket_proxy_net` | `glances`, `dozzle`, `monitoring-socket-proxy` (internal only) |

Only required services are dual-homed. Cross-network exposure is minimized by design.

---

## Threat Model

This stack assumes:
- Trusted LAN and VPN clients
- No hostile internal actors
- No direct internet exposure

It is not designed as a hardened, internet-facing production environment.

---

## Secret Handling

Files that must never be committed:

- `config/stepca/password.txt`
- `.env`
- Any private keys under `config/stepca/`

Ensure these paths are covered by `.gitignore`. Only example/template files are tracked (`.example` variants).

Note: Compromise of step-ca private keys requires complete CA rotation and client trust reinstallation.

---

## Known Limitations and Accepted Trade-offs

### Glances — `pid: host`

Glances runs with `pid: host` to access host-level process and resource metrics. This grants the container visibility into all host processes via `/proc`.

**Risk:** A compromised Glances container could read process metadata from the host.

**Mitigation:** Glances is protected behind Authelia (one-factor auth) and is reachable only from the LAN. The threat model does not include hostile LAN actors.

### Pi-hole — No Web Password

Pi-hole's built-in web password is intentionally left empty (`FTLCONF_webserver_api_password: ""`). Authelia is the sole authentication layer for the Pi-hole web UI.

**Risk:** If Authelia is unavailable (crash, misconfiguration), the Pi-hole web UI is accessible without authentication from the LAN.

**Mitigation:** Authelia has a health check and restarts automatically. No LAN-hostile actors are assumed.

### Authelia — One-Factor Authentication Only

Access control is configured with `policy: one_factor` for all services. Two-factor authentication (TOTP/WebAuthn) is not enforced.

**Rationale:** Single-user home lab on a trusted LAN. Adding 2FA is possible in `config/authelia/configuration.yml` if the threat model changes.

### No `no-new-privileges` / `cap_drop` on Most Containers

Only the Docker socket proxy has explicit capability dropping (`cap_drop: ALL`) and `no-new-privileges: true`. Other services (Traefik, Pi-hole, Authelia, Glances, etc.) run without these constraints.

**Rationale:** Compatibility and simplicity for a single-user home environment. Applying `cap_drop: ALL` to services like Pi-hole requires identifying and restoring each needed capability individually.

### No Container Resource Limits

No CPU or memory limits are set on any container. A misbehaving or compromised container could consume host resources.

**Rationale:** Accepted for a home server with a single operator. Can be added per-service if resource contention becomes a concern.