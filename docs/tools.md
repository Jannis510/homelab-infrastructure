# Web Tools

Lightweight single-purpose tools that run behind Traefik with Authelia protection. No dedicated documentation — this page covers all of them.

---

## BentoPDF

PDF utility suite — merge, split, compress, convert, and more.

**URL:** `https://bentopdf.app.home.arpa`

No environment variables required. No persistent storage — all processing is in-memory.

```bash
docker compose -f services/bentopdf/compose.yml up -d
docker compose -f services/bentopdf/compose.yml down
```

---

## ConvertX

File format converter — supports images, audio, video, documents, and more.

**URL:** `https://convertx.app.home.arpa`

**Environment variables** (`services/convertx/.env`):

| Variable | Description |
|----------|-------------|
| `CONVERTX_JWT_SECRET` | JWT signing secret — generate with `openssl rand -hex 32` |

```bash
docker compose -f services/convertx/compose.yml up -d
docker compose -f services/convertx/compose.yml down
```