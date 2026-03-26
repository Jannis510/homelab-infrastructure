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
```

Removes containers **and** volumes. All services reinitialize from scratch on next start.

> **Warning:** step-ca generates a new Certificate Authority on reinit. Previously issued certificates
> become untrusted and all clients must reinstall the new Root CA.

---

## Regenerating PKI Export Artifacts

After `docker compose down -v`, remove stale artifacts before restarting:

```bash
rm -rf artifacts/pki/*
docker compose run --rm stepca-export
```

Fresh artifacts will be available at:

```
artifacts/pki/roots.pem
artifacts/pki/root_ca.crt
```

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