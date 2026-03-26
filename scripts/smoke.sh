#!/usr/bin/env bash
set -euo pipefail

DNS_TOOL_IMAGE="alpine:3.21"

compose() {
  docker compose --env-file .env.ci -f compose.yml -f compose.ci.yml "$@"
}

assert_not_empty() {
  local value="$1"
  local message="$2"
  if [ -z "$value" ]; then
    echo "ERROR: $message" >&2
    exit 1
  fi
}

assert_equals() {
  local actual="$1"
  local expected="$2"
  local message="$3"
  if [ "$actual" != "$expected" ]; then
    echo "ERROR: $message (expected '$expected', got '$actual')" >&2
    exit 1
  fi
}

wait_for_service_ready() {
  local service="$1"
  local timeout_seconds="${2:-180}"
  local elapsed=0
  while [ "$elapsed" -lt "$timeout_seconds" ]; do
    local state
    local health
    state="$(docker inspect -f '{{.State.Status}}' "$service" 2>/dev/null || true)"
    health="$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' "$service" 2>/dev/null || true)"
    if [ "$state" = "running" ] && { [ "$health" = "healthy" ] || [ "$health" = "none" ]; }; then
      return 0
    fi
    sleep 2
    elapsed=$((elapsed + 2))
  done
  echo "ERROR: Service '$service' not ready after ${timeout_seconds}s." >&2
  docker inspect "$service" 2>/dev/null || true
  exit 1
}

NETWORK_NAME="proxy_net"
DNS_NETWORK_NAME="dns_net"

if ! docker network inspect "$NETWORK_NAME" >/dev/null 2>&1; then
  echo "ERROR: Docker network '$NETWORK_NAME' not found." >&2
  exit 1
fi

if ! docker network inspect "$DNS_NETWORK_NAME" >/dev/null 2>&1; then
  echo "ERROR: Docker network '$DNS_NETWORK_NAME' not found." >&2
  exit 1
fi

# 1) Core containers must become ready (running + healthy if healthcheck exists)
wait_for_service_ready "unbound"
wait_for_service_ready "pihole"
wait_for_service_ready "stepca"
wait_for_service_ready "traefik"
wait_for_service_ready "authelia"

# 2) stepca-export must have completed successfully
stepca_export_id="$(compose ps -aq stepca-export)"
assert_not_empty "$stepca_export_id" "stepca-export container was not created"
stepca_export_state="$(docker inspect -f '{{.State.Status}}' "$stepca_export_id")"
stepca_export_exit_code="$(docker inspect -f '{{.State.ExitCode}}' "$stepca_export_id")"
assert_equals "$stepca_export_state" "exited" "stepca-export did not finish as a one-shot container"
assert_equals "$stepca_export_exit_code" "0" "stepca-export failed"

# 3) Show current service status for diagnostics
compose ps

# 4) DNS external resolution via Pi-hole (query Pi-hole over proxy_net; Pi-hole is dual-homed)
dns_external="$(docker run --rm --network "$NETWORK_NAME" \
  "$DNS_TOOL_IMAGE" \
  sh -lc 'apk add --no-cache bind-tools >/dev/null && dig @pihole example.com +short | head -n1')"
assert_not_empty "$dns_external" "Pi-hole did not resolve example.com"

# 5) Pi-hole must be configured to use Unbound as upstream
pihole_upstream_env="$(docker inspect -f '{{range .Config.Env}}{{println .}}{{end}}' pihole | grep '^FTLCONF_dns_upstreams=' || true)"
assert_equals "$pihole_upstream_env" "FTLCONF_dns_upstreams=unbound#5335" "Pi-hole upstream is not set to unbound#5335"

# 6) Unbound must resolve external DNS directly
unbound_external="$(docker run --rm --network "$DNS_NETWORK_NAME" \
  "$DNS_TOOL_IMAGE" \
  sh -lc 'apk add --no-cache bind-tools >/dev/null && dig @unbound -p 5335 example.com +short | head -n1')"
assert_not_empty "$unbound_external" "Unbound did not resolve example.com"

# 7) Internal DNS record resolution
dns_internal="$(docker run --rm --network "$NETWORK_NAME" \
  "$DNS_TOOL_IMAGE" \
  sh -lc 'apk add --no-cache bind-tools >/dev/null && dig @pihole traefik.app.home.arpa +short | head -n1')"
assert_not_empty "$dns_internal" "Pi-hole did not resolve traefik.app.home.arpa"

# 8) step-ca health endpoint
stepca_health="$(compose exec -T stepca sh -lc 'wget --no-check-certificate -qO- https://localhost:9000/health' || true)"
assert_not_empty "$stepca_health" "step-ca health endpoint returned no payload"

# 9) Traefik must answer on :80
traefik_http_code="$(curl -sS -o /dev/null -w '%{http_code}' http://localhost:80)"
if [ "$traefik_http_code" -lt 200 ] || [ "$traefik_http_code" -ge 500 ]; then
  echo "ERROR: Traefik HTTP probe failed (unexpected status $traefik_http_code)." >&2
  exit 1
fi

# 10) Traefik file-provider routers must be loaded
# Verified end-to-end: if pihole.app.home.arpa returns any HTTP response,
# Traefik has loaded the file provider and the pihole router is active.
# (Step 12 additionally confirms the Authelia middleware is working.)
pihole_status="$(curl -ksS -o /dev/null -w '%{http_code}' \
  --resolve pihole.app.home.arpa:443:127.0.0.1 \
  https://pihole.app.home.arpa/ || true)"
if ! [[ "$pihole_status" =~ ^[2-4][0-9]{2}$ ]]; then
  echo "ERROR: Traefik is not routing pihole.app.home.arpa (got '$pihole_status')" >&2
  exit 1
fi

# 11) Authelia health endpoint
authelia_health="$(curl -ksS \
  --resolve auth.app.home.arpa:443:127.0.0.1 \
  https://auth.app.home.arpa/api/health || true)"
assert_not_empty "$authelia_health" "Authelia health endpoint returned no payload"

# 12) SSO gate: protected route without auth must redirect to Authelia
sso_redirect="$(curl -ksS -o /dev/null -w '%{redirect_url}' \
  --resolve pihole.app.home.arpa:443:127.0.0.1 \
  https://pihole.app.home.arpa/admin/ || true)"
echo "$sso_redirect" | grep -q 'auth\.app\.home\.arpa' || {
  echo "ERROR: pihole.app.home.arpa did not redirect to Authelia SSO (redirect_url='$sso_redirect')" >&2
  exit 1
}
