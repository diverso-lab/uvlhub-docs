---
layout: default
title: webhook
parent: Features
permalink: /features/webhook
nav_order: 10
---

# webhook
{: .no_toc }

The `webhook` feature is the receiving end of the continuous deployment pipeline. It exposes exactly
one endpoint, `POST /webhook/deploy`, and answering that request performs a **real, in-place
redeployment** of the running application: pull the latest code, reinstall dependencies, run the
database migrations, log the deployment and restart the web container through the Docker socket.

It is declared in both `features_dev` and `features_prod` in `[tool.splent]`: development and
testing need it for its own suite, and production needs it because the continuous-deployment
pipeline posts to it after every green test run. And together with
[team]({{site.baseurl}}/features/team) it is one of only two features that import nothing from any
other feature and that no other feature imports — fully decoupled in both directions.

{: .warning }
**Never call `/webhook/deploy` by hand against a stack you care about.** A successful POST is not a
health check: it pulls `main`, reinstalls requirements, migrates the database and restarts the web
container. Everything below is documented from the source; nothing here requires invoking it.

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

## What it does

The intended caller is GitHub Actions. `.github/workflows/CD_webhook.yml` runs after the `Pytest`
workflow completes successfully on `main` and fires the deployment:

{% raw %}
```yaml
- name: Trigger Deployment Webhook
  run: |
    curl -X POST \
      https://${{ secrets.WEBHOOK_DOMAIN }}/webhook/deploy \
      -H "Authorization: Bearer ${{ secrets.WEBHOOK_TOKEN }}"
```
{% endraw %}

The feature itself is one route plus one service. The route authenticates the request; the service
carries out the deployment against the Docker daemon, whose socket is mounted into the web container
by the deployment compose file.

`webhook` sits in both environment lists, so the app factory's environment mapping (`prod` for
`config_name="production"`, `dev` for everything else, with `FLASK_ENV` supplying the config name)
registers it everywhere. In production the endpoint exists for the deployment pipeline and relies on
its token guard: without a configured `WEBHOOK_TOKEN` it answers 503 for every request, so enabling
the feature does not open an unauthenticated surface. See
[Feature selection]({{site.baseurl}}/architecture/feature_selection) for the full mechanism.

## Routes

| Endpoint | Methods | Rule |
|:---------|:--------|:-----|
| `webhook.deploy` | POST | `/webhook/deploy` |
| `webhook.assets` | GET | `/webhook/<subfolder>/<filename>` |

`webhook.assets` is added automatically by `BaseBlueprint` for the feature's `assets/` folder. The
real surface is `webhook.deploy`, and its authorization logic is the part worth reading closely.
This is the whole view:

```python
@webhook_bp.route("/webhook/deploy", methods=["POST"])
def deploy():
    # Read the token per request so configuration changes are picked up and an
    # unset variable can never be matched by a crafted "Bearer None" header.
    token = os.environ.get("WEBHOOK_TOKEN")
    if not token:
        return jsonify({"error": "Webhook token is not configured"}), 503

    authorization = request.headers.get("Authorization", "")
    if not hmac.compare_digest(authorization.encode("utf-8"), f"Bearer {token}".encode("utf-8")):
        abort(403, description="Unauthorized")

    webhook_service.deploy()
    return "Deployment successful", 200
```

Three properties make up the security model:

- **The token is read per request**, not at import time. A token rotated in the environment is
  picked up without a restart, and there is no stale module-level copy to match against.
- **An unconfigured endpoint refuses to work.** If `WEBHOOK_TOKEN` is unset *or* empty, the endpoint
  answers 503 before looking at the request. This closes the classic hole where an unset variable
  stringifies to `None` and a crafted `Authorization: Bearer None` header would authenticate — with
  no token configured, no header value can succeed.
- **The comparison is constant-time.** The full header is compared against `Bearer <token>` with
  `hmac.compare_digest`, so an attacker cannot measure how many leading characters matched. A wrong
  token, a raw token without the `Bearer` prefix, or a missing header all get 403.

Only after all three gates does `webhook_service.deploy()` run. GET requests get 405 from Flask's
routing, before any of this logic.

## Models

`models.py` defines `Webhook` with a single `id` column, and `migrations/versions/001.py` creates the
matching (empty) table. Nothing in the deployment flow reads or writes it — the model, along with
`WebhookRepository`, the unused `WebhookForm` in `forms.py` and the empty `WebhookSeeder`, is
scaffolding from `feature:create` that was never given a domain. The feature's actual state lives
outside the database, in `/workspace/deployments.log`.

## Services

`WebhookService` extends `BaseService` and holds the whole deployment procedure. At import time it
opens a Docker client against the daemon socket:

```python
client = docker.from_env()
```

This works because the deployment stack mounts `/var/run/docker.sock` into the web container — the
Flask process controls its own sibling containers through the host's Docker daemon.

`deploy()` is a five-step sequence, run in order:

```python
def deploy(self) -> None:
    """End-to-end deploy: pull latest, refresh deps, migrate, log, restart."""
    container = self.get_web_container()
    self.execute_container_command(container, "/workspace/scripts/git_update.sh")
    self.execute_container_command(container, "pip install -r requirements.txt")
    self.execute_container_command(container, "flask db upgrade")
    self.log_deployment(container)
    self.restart_container(container)
```

1. **Find the web container.** `get_web_container()` asks the daemon for the container named
   `web_app_container` and aborts 404 if it does not exist.
2. **Update the code.** `scripts/git_update.sh` runs inside the container via `exec_run`. It pulls
   `origin main`; if the remote is an SSH URL it temporarily rewrites it to HTTPS for the pull and
   restores it afterwards.
3. **Refresh dependencies.** `pip install -r requirements.txt`, also via `exec_run` in `/workspace`.
4. **Migrate.** `flask db upgrade` applies any migrations the pull brought in.
5. **Log and restart.** `log_deployment` appends a UTC-timestamped line to
   `/workspace/deployments.log`, then `restart_container` launches
   `scripts/restart_container.sh <container id>` with `subprocess.Popen`. The script sleeps five
   seconds and runs `docker restart` — the detached `Popen` plus the sleep give the HTTP response
   time to leave before the container restarts itself.

Every `exec_run` step is checked: a non-zero exit aborts 500 with the command's output in the
description, the chain stops at the first failure, and the container is never restarted after a
failed step — the service tests assert exactly this ordering.

Two helpers, `get_volume_name` and `execute_host_command` (which runs a command in a throwaway
`docker run` with the workspace volume and the Docker socket mounted), are implemented and
unit-tested but not called by `deploy()`; the current flow does everything through `exec_run` in the
existing container.

## Dependencies

Measured from the imports, in both directions:

- **From other features: nothing.** The feature imports its own modules, `app` (for `db`), the
  `splent_framework` base classes, and the third-party `docker` SDK and `python-dotenv`.
- **Into other features: nothing.** No file outside `app/features/webhook/` references the feature.

Its real dependencies are operational rather than Python-level, and all are provided by the
deployment stack (see [Configuration](#configuration)):

- the Docker socket mounted at `/var/run/docker.sock`;
- the Docker CLI inside the image (`docker/images/Dockerfile.webhook` installs `docker-ce-cli` and
  `git`);
- `scripts/git_update.sh` and `scripts/restart_container.sh` available under `/workspace/scripts`;
- a web container named exactly `web_app_container`.

## Templates and assets

`templates/webhook/index.html` extends the base template with an empty content block, and no route
renders it — like the model, it is scaffolding. `assets/js/scripts.js` is a single `console.log`
line; `init_feature` registers it with the asset registry, and since the shared layout emits every
registered `js` asset on every page, that line runs on every page of a development stack.

## Tests

Four files, and two deliberate absences:

```
app/features/webhook/tests/
├── test_unit.py
├── test_repository.py
├── test_service.py
└── test_integration.py
```

The invariant across all of them: **a real deployment can never run from the test suite.** Every side
effect is replaced by a stub or a recorder, and the service tests stub `subprocess.run` with
`pytest.fail("deploy() must not run host subprocesses")` — if anything in `deploy()` ever reaches a
host subprocess, the test fails rather than executing it.

- `test_unit.py` (`unit`) exercises each helper against fake containers that record `exec_run` calls
  instead of executing them: volume resolution, the 404 on a missing container, the 500 on a failed
  command, the exact `docker run` argv `execute_host_command` would build, the log line format, and
  the restart script invocation.
- `test_repository.py` (`repository`) covers CRUD on the bare `Webhook` row against the test
  database.
- `test_service.py` (`service`) asserts the orchestration of `deploy()`: the three commands in
  order, the log line, the restart last, the chain stopping at the first failing command with
  nothing run after it, and the 404 when the web container is missing.
- `test_integration.py` (`integration`) drives `/webhook/deploy` through the Flask test client with
  `deploy` monkeypatched to a recorder, covering the full authorization matrix: no header, wrong
  token, raw token without `Bearer` (all 403 with zero deploy calls); valid token (200, exactly one
  call); unset and empty `WEBHOOK_TOKEN` (503); the literal `Bearer None` header against an unset
  token (503, never a match); GET (405); and a deploy failure surfacing as 500.

```
rosemary test webhook --unit
rosemary test webhook --repository
rosemary test webhook --service
rosemary test webhook --integration
```

There is **no `test_selenium.py` and no `locustfile.py`**, and that is by design, not omission. The
feature's only endpoint performs a real redeployment: a browser test would have nothing to look at
(there is no page), and a load test would be a denial-of-service against the test environment itself
— every simulated user would trigger a pull, a reinstall, a migration and a container restart of the
very stack serving the test.

## Configuration

`WEBHOOK_TOKEN` is the one variable the feature reads. It has no `.env.example` of its own (unlike
`zenodo`); the token is set at stack level, and `.env.docker.production.example` carries the
placeholder:

```
WEBHOOK_TOKEN=<CHANGE_THIS>
```

Without it, the endpoint answers 503 for every request — the feature fails closed, never open.

Feature selection is the other half of its configuration. `webhook` is declared in both environment
lists of the root `pyproject.toml`, so the endpoint exists in development and in production alike:

```toml
features_dev = [
    "webhook",
]
features_prod = [
    "webhook",
]
```

The repository also ships the deployment stack built around this feature:

- `docker/docker-compose.prod.webhook.yml` — mounts the repository at `/workspace`, the scripts, and
  the Docker socket into the web container, and builds it from `docker/images/Dockerfile.webhook`;
- `docker/images/Dockerfile.webhook` — the web image plus `git` and the Docker CLI, which the
  deployment steps need;
- `.github/workflows/CD_webhook.yml` — the caller, using the `WEBHOOK_DOMAIN` and `WEBHOOK_TOKEN`
  repository secrets.

{: .warning }
The shipped deployment stack and the feature lists currently disagree. `.env.docker.production.example`
sets `FLASK_ENV=production`, and under that environment the loader resolves `features` plus
`features_prod` — which does not include `webhook` — so a stack built from these files answers 404 on
`/webhook/deploy` and the CD workflow's POST cannot reach the feature. To actually use the pipeline,
`webhook` would have to be declared under `features_prod` (accepting the security model above as the
only gate) or the stack run with a non-production `FLASK_ENV`.
