# Homepage Dashboard

[Homepage](https://gethomepage.dev) is a self-hosted start page that provides a central overview of all running services, system resources, and quick links.

It is an optional service and runs independently from the core stack.

---

## URL

```
https://start.app.home.arpa
```

Access is protected by Authelia (SSO, same session as all other services).

---

## Starting the Service

Requires the core stack to be running first:

```bash
# Start core stack
docker compose up -d

# Start Homepage
docker compose -f services/homepage/compose.yml up -d
```

Stop:

```bash
docker compose -f services/homepage/compose.yml down
```

---

## Configuration

All configuration files are located under `services/homepage/config/`.

| File | Purpose |
|------|---------|
| `settings.yaml` | Theme, layout, header style |
| `services.yaml` | Service cards (links, icons, descriptions) |
| `widgets.yaml` | Top info bar (weather, Pi-hole stats, resources) |
| `bookmarks.yaml` | Quick-access external links |
| `custom.css` | Visual customization |

Changes to config files are picked up by Homepage without a restart.

---

## Environment Variables

Widget values that vary per deployment are injected via `.env`:

| Variable | Description |
|----------|-------------|
| `HOMEPAGE_VAR_WEATHER_CITY` | City label shown in the weather widget |
| `HOMEPAGE_VAR_WEATHER_LAT` | Latitude for Open-Meteo weather data |
| `HOMEPAGE_VAR_WEATHER_LON` | Longitude for Open-Meteo weather data |
| `HOMEPAGE_VAR_PIHOLE_API_KEY` | Pi-hole v6 API key (Settings → API & Privacy) |

Weather data is sourced from [Open-Meteo](https://open-meteo.com) — no API key or registration required.

---

## Adding New Services

Add entries to `services/homepage/config/services.yaml`:

```yaml
- Group Name:
    - Service Name:
        href: https://service.app.home.arpa
        description: Short description
        icon: icon-name.png
```

Icons are resolved automatically from [Dashboard Icons](https://github.com/walkxcode/dashboard-icons).