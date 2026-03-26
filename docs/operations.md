# Operations

## Common Commands

```bash
docker compose up -d                    # start / apply changes
docker compose down                     # stop (keep volumes)
docker compose ps                       # status
docker compose logs -f                  # logs, all services
docker compose logs -f <service>        # logs, single service
docker compose restart <service>        # restart single service
```

---

## Volumes and Data Persistence

Docker volumes store persistent state (Pi-hole, Unbound, step-ca configuration and keys).
Volumes survive container restarts and `docker compose down`.

```bash
docker compose config --volumes         # list declared volumes
docker volume ls                        # list all Docker volumes
```

---

## Soft Reset (keep data)

```bash
docker compose down
docker compose up -d
```

Reuses existing volumes — CA remains unchanged, Pi-hole data persists.

---

## Hard Reset (data loss)

```bash
docker compose down -v
rm -rf artifacts/pki/*
docker compose --profile init up -d
```

Removes containers **and** volumes. `stepca-export` re-runs via `--profile init` to write fresh Root CA artifacts before Traefik starts.

> **Warning:** step-ca generates a new Certificate Authority on reinit. Previously issued certificates
> become untrusted and all clients must reinstall the new Root CA.

---

## Regenerating PKI Export Artifacts

After `docker compose down -v`, remove stale artifacts before restarting:

```bash
rm -rf artifacts/pki/*
docker compose --profile init up -d
```

This runs `stepca-export` once (via the `init` profile) to write fresh artifacts, then starts all services.
Fresh artifacts will be available at:

```
artifacts/pki/roots.pem
artifacts/pki/root_ca.crt
```

> **Note:** On all subsequent starts, use `docker compose up -d` without `--profile init`.
> The export service is skipped and the artifacts on disk are reused.

---

## Optional Services

Optional services run independently from the core stack:

```bash
# Start
docker compose -f services/<name>/compose.yml up -d

# Stop
docker compose -f services/<name>/compose.yml down
```

---

## Cleanup

Remove unused images and build cache (volumes are not affected):

```bash
docker system prune
```

Remove unused resources **including volumes** (destructive):

```bash
docker system prune --volumes
```