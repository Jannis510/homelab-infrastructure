# Authentication (Authelia)

All services exposed through Traefik are protected by [Authelia](https://www.authelia.com), acting as a ForwardAuth middleware. Unauthenticated requests are redirected to the login portal.

Login portal: `https://auth.app.home.arpa`

A single login session covers all services under `*.app.home.arpa`.

---

## Access Policy

The default policy is **deny**. All services under `*.app.home.arpa` require at minimum one-factor authentication (username + password).

Policy is defined in `config/authelia/configuration.yml`.

---

## User Management

Users are managed in a local flat-file backend:

```
config/authelia/users_database.yml
```

Copy the example as a starting point:

```bash
cp config/authelia/users_database.yml.example config/authelia/users_database.yml
```

Passwords must be stored as **Argon2id** hashes. Generate with:

```bash
docker run --rm authelia/authelia:4.39 authelia crypto hash generate argon2 --password 'your-password'
```

---

## Secrets

Set the following in `.env`:

| Variable | Description |
|----------|-------------|
| `AUTHELIA_SESSION_SECRET` | Session encryption key |
| `AUTHELIA_STORAGE_ENCRYPTION_KEY` | Storage encryption key |
| `AUTHELIA_JWT_SECRET` | JWT token signing key |

Generate each with:

```bash
openssl rand -hex 32
```