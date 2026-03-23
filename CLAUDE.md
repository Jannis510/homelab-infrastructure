## Project Overview

**Name:** home-server
**Purpose:** A Docker Compose-based homelab stack for running secure, self-hosted services on a home LAN.

### Problem & Audience
Provides privacy, data sovereignty, and network control for personal use on a single home server.
Designed and operated by one person — not a team product.

### Core Services
| Service | Role |
|---------|------|
| Pihole | LAN-wide DNS resolver and ad blocker |
| Unbound | Recursive upstream DNS (used by Pihole) |
| Traefik | Reverse proxy — all services route through it |
| Step-CA | Internal PKI for HTTPS certificates |
| Trivy | Container image vulnerability scanning (CI) |

Future services are always added behind Traefik and integrated into this core stack.

### Deployment Environment
Single physical or virtual server on a private home LAN. No cloud. No public internet exposure.

### Non-Goals
- No public internet access / no router port forwarding to services
- Not designed for multi-user or multi-host setups

### Architectural Principles (always respect these)
1. **Security-first:** LAN-only port binding, least-privilege containers, network segmentation, internal PKI
2. **Fully reproducible:** Everything runs via Docker Compose — no manual setup steps outside of it
3. **Clean & minimal:** Prefer simple, explicit configuration over complexity; simplicity is acceptable only when it does not compromise security

## Git
- Never run `git commit` without explicit user confirmation
- Always show the proposed commit message and wait for approval before committing

## Commit Messages

Format: `type(scope): kurze Beschreibung im Imperativ`

**Types:** `fix` | `chore` | `ci` | `docs`

**Scopes** (examples — list grows as services are added): `security` | `ci` | `pihole` | `traefik` | `unbound` | `stepca` | `trivy` | `readme`

**Rules:**
- Imperative, lowercase: `add`, `fix`, `update` — not `added`, `fixes`
- No trailing period
- Omit scope when multiple unrelated services are changed with no fitting parent scope
- Security changes always use scope `security`, even when multiple services are affected
- Version bumps: `chore(scope): update X to vY.Z.Z`