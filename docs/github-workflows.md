# GitHub Workflows

This section documents the GitHub Actions workflows used to validate, test, and secure the infrastructure stack.

Workflows are located in:

```
.github/workflows/
```

* `ci.yml`
* `smoke.yml`
* `security.yml`

---

## Continuous Integration (`ci.yml`)

**Purpose:** Fast validation for every pull request and push to `main`.

### Triggers

* `pull_request`
* `push` on `main`

### Job: `validate-and-lint` (ubuntu-latest)

### Validation Steps

1. **Compose Validation**

```bash
docker compose --env-file .env.ci -f compose.yml -f compose.ci.yml config >/dev/null
```

Ensures that the combined Compose configuration is syntactically valid and fully resolvable.

2. **YAML Linting**
   Uses `ibiqlik/action-yamllint@v3` to enforce YAML formatting standards.

3. **ShellCheck**
   Performs static analysis of shell scripts under `config/` and `scripts/`.

4. **Policy Checks**

* Forbid floating `:latest` image tags
* Prevent `level: DEBUG` in `config/traefik/traefik.yml` on protected branches

CI failures block merges if configuration validity or policy compliance is violated.

---

## Smoke Test (`smoke.yml`)

**Purpose:** Full-stack integration validation in CI.

### Triggers

* `workflow_dispatch`
* `pull_request` (infrastructure-related changes)
* `push` to `main` (with path filters)

### Job: `smoke` (ubuntu-latest, 10-minute timeout)

### Execution Flow

1. **Prepare CI-only files and secrets**

* `config/stepca/password.txt`
* `config/traefik/usersfile`
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

* Required Docker networks exist
* Containers are running and healthy
* `stepca-export` completed successfully
* DNS resolution via Pi-hole and Unbound
* Internal DNS for `*.home.arpa`
* `step-ca` health endpoint responsiveness
* Traefik HTTP responsiveness
* Traefik router registration (pihole@file)

This ensures that the stack behaves correctly as an integrated system, not only at a syntactic level.

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
