# Troubleshooting

## Traefik Dashboard Login Fails

**Symptoms:** `401 Unauthorized` or redirect loop when accessing `traefik.app.home.arpa`.

- Confirm Authelia is running: `docker compose ps authelia`
- Check Authelia logs: `docker compose logs authelia`
- Verify `config/authelia/users_database.yml` exists and credentials are correct

```bash
docker compose restart traefik authelia
```

---

## DNS Records Not Resolving

**Symptoms:** `*.app.home.arpa` does not resolve, services unreachable in browser.

```bash
docker compose ps
nslookup pihole.app.home.arpa <HOST_IP>
```

Check:
- `SERVER_LOCAL_IP` in `.env` matches the host's LAN IP
- Client devices use the Pi-hole host as their DNS server
- No competing DNS server via router override or DHCP misconfiguration

---

## HTTPS Certificate Warnings

**Symptoms:** Browser reports an untrusted certificate.

- Confirm `artifacts/pki/root_ca.crt` is installed on the client device
- Verify in the browser that the issuer matches the internal step-ca

If volumes were reset: a new CA was generated — reinstall the newly generated Root CA on all clients.

---

## Port 53 Already in Use (Linux)

**Symptoms:** Docker fails to start Pi-hole with "address already in use".

**Cause:** `systemd-resolved` may bind to port 53 by default on Debian/Ubuntu.

```bash
sudo lsof -i :53
```

Either disable `systemd-resolved` or reconfigure it to not bind on `0.0.0.0`.