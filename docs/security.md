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