# Security Exceptions – Trivy

This document tracks accepted/ignored Trivy findings where no upstream fix is available yet.
Exceptions are reviewed on new upstream releases.

## Pending upstream image rebuilds

The following CVEs are fixed upstream but not yet included in the affected container images.

### CVE-2026-33186 — gRPC-Go authorization bypass (CRITICAL)
- **Affected image:** `traefik:v3.6.11` (gobinary: `usr/local/bin/traefik`)
- **Component:** `google.golang.org/grpc` v1.79.1
- **Fix available in:** grpc v1.79.3
- **Rationale:** Awaiting traefik rebuild with updated grpc dependency.

Review trigger: New traefik release built with grpc >= 1.79.3.

### CVE-2026-22184 — zlib buffer overflow (HIGH)
- **Affected images:** `traefik:v3.6.11`, `pihole/pihole:2026.02.0`
- **Component:** `zlib` 1.3.1-r2
- **Fix available in:** zlib 1.3.2-r0
- **Rationale:** Awaiting image rebuilds with updated Alpine base layer.

Review trigger: New traefik or pihole releases based on Alpine with zlib >= 1.3.2-r0.

### CVE-2026-32767 — libexpat SQL injection bypass (CRITICAL)
- **Affected image:** `pihole/pihole:2026.02.0`
- **Component:** `libexpat` 2.7.4-r0
- **Fix available in:** libexpat 2.7.5-r0
- **Rationale:** Awaiting pihole image rebuild with updated Alpine base layer.

Review trigger: New pihole release based on Alpine with libexpat >= 2.7.5-r0.

---

Stack is LAN-only, not publicly exposed. All CVEs have upstream fixes; exceptions
are temporary until the respective images are rebuilt.