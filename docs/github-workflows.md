# GitHub Workflows

This section documents the GitHub Actions workflows used to validate, test, and secure the infrastructure stack.

Workflows are located in:

```
.github/workflows/
```

* `ci.yml`
* `smoke.yml`
* `security.yml`
* `services.yml`

---

## Continuous Integration (`ci.yml`)

**Purpose:** Fast validation for every pull request and push to `main`.

### Triggers

* `pull_request`
* `push` on `main`

### Job: `validate-and-lint` (ubuntu-latest)

### Validation Steps

1. **Compose Validation**

Validates the core stack and all optional service stacks. If a service has no `.env.example`, validation runs without an env file:

```bash
docker compose --env-file .env.ci -f compose.yml -f compose.ci.yml config >/dev/null
for f in services/*/compose.yml; do
  # uses .env.example if present, otherwise validates without env file
  docker compose [-f .env.example] -f "$f" config >/dev/null
done
```

2. **YAML Linting**
   Uses `ibiqlik/action-yamllint@v3` to enforce YAML formatting standards.

3. **ShellCheck**
   Performs static analysis of shell scripts under `config/` and `scripts/`.

4. **Policy Checks**

* Forbid floating `:latest` image tags
* **All Traefik route files must include `authelia@file` middleware** — every file in `config/traefik/dynamic/` that defines routers must reference the Authelia ForwardAuth middleware. `authelia.yml` itself is excluded (it is the SSO portal).
* Prevent `level: DEBUG` in `config/traefik/traefik.yml` on protected branches

CI failures block merges if configuration validity or policy compliance is violated.

---

## Smoke Test (`smoke.yml`)

**Purpose:** Full-stack integration validation in CI.

### Triggers

* `workflow_dispatch`
* `pull_request` on changes to: `compose.yml`, `compose.ci.yml`, `config/**`, `scripts/**`
* `push` to `main` on the same paths

> `services/**` is intentionally excluded — optional services are not started in this test. They are validated separately by the Services workflow.

### Job: `smoke` (ubuntu-latest, 10-minute timeout)

### Execution Flow

1. **Prepare CI-only files and secrets**

* `config/stepca/password.txt`
* Ensure `artifacts/pki/` exists

2. **Start the stack**

```bash
docker compose --env-file .env.ci -f compose.yml -f compose.ci.yml up -d --build
```

3. **Run integration tests**

```bash
scripts/smoke.sh
```

4. **On Failure**

* Dump container status
* Print recent logs

5. **Cleanup (always)**

```bash
docker compose --env-file .env.ci -f compose.yml -f compose.ci.yml down -v --remove-orphans
```

### What Is Validated

* Required Docker networks exist (`proxy_net`, `dns_net`)
* All core containers are running and healthy — including **Authelia**
* `stepca-export` completed successfully
* DNS resolution via Pi-hole and Unbound
* Internal DNS for `*.app.home.arpa`
* `step-ca` health endpoint responsiveness
* Traefik HTTP responsiveness
* Traefik router registration (`pihole@file`)
* **Authelia health endpoint** (`/api/health`) is reachable via HTTPS
* **SSO gate** — accessing `pihole.app.home.arpa` without a session redirects to `auth.app.home.arpa`

This ensures that the stack behaves correctly as an integrated system, not only at a syntactic level.

---

## Services (`services.yml`)

**Purpose:** Validates optional services in `services/` for correctness and isolation from the core stack.

### Triggers

* `workflow_dispatch`
* `pull_request` on changes to: `services/**`, `.github/workflows/services.yml`
* `push` to `main` on the same paths

### Job: `isolation-check` (ubuntu-latest)

### Steps

1. **Compose Validation**

Each `services/*/compose.yml` is validated with `docker compose config`. Uses `.env.example` if present, otherwise validates without an env file.

2. **Isolation Rules** (enforced via Python/PyYAML)

| Rule | Rationale |
|------|-----------|
| No `ports:` — only `expose:` allowed | All traffic must route via Traefik |
| All top-level `networks:` must have `external: true` | Services must attach to core stack networks, not define their own |

Violations fail the workflow with an error per offending file and rule.

---

## Security Scan (`security.yml`)

**Purpose:** Continuous vulnerability assessment of source code and container images.

### Triggers

* `workflow_dispatch`
* `pull_request` (security-relevant paths)
* `push` to `main`

### Permissions

```yaml
contents: read
security-events: write
```

### Jobs

#### 1. `fs-scan`

* Trivy filesystem scan (severity: CRITICAL, HIGH)
* Generates SARIF report
* Uploads results to GitHub Security tab
* Stores scan artifacts

#### 2. `image-scan` (scheduled or manual only)

* Pulls all images defined in Compose
* Scans each image with Trivy (CRITICAL, HIGH)
* Uploads SARIF reports and artifacts

### Security Handling Strategy

Security findings should be triaged and resolved by:

* Updating image versions
* Adjusting configuration
* Documenting accepted risk (if formally justified)