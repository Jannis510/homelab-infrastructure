# Security Exceptions – Trivy

This document tracks accepted/ignored Trivy findings where no upstream fix is available yet.
Exceptions are reviewed on new upstream releases.

## smallstep/step-ca

### OpenSSL (upstream base image pending)
- CVE-2025-15467
- CVE-2025-69419
- CVE-2025-69421

Rationale: Awaiting upstream image rebuild. Stack is LAN/VPN-only, not publicly exposed.

Review trigger: New step-ca image release including the patched OpenSSL package.

### Go stdlib (awaiting step-ca rebuild with Go >= 1.25.7)
- CVE-2025-68121
- CVE-2025-61726
- CVE-2025-61728
- CVE-2025-61730

Rationale: Awaiting upstream rebuild. Restricted exposure (internal networks only).

Review trigger: step-ca release built with Go >= 1.25.7.

### Nebula (not used)
- CVE-2026-25793

Rationale: Component not used in this deployment.

Review trigger: If nebula is introduced or step-ca changes dependencies.