---
layout: default
grand_parent: CI/CD
parent: Continuous deployment
title: Webhook workflow
permalink: /ci_cd/continuous_deployment/webhook_workflow
nav_order: 2
---

# Webhook workflow
{: .no_toc }

{: .important-title }
>
> Path to file [(view file on GitHub)](https://github.com/diverso-lab/uvlhub/blob/main/.github/workflows/CD_webhook.yml)
> 
> The original file is located at the following path:
>
> ```
> .github / workflows / CD_webhook.yml 
> ```

This GitHub Actions workflow deploys {% include uvlhub.html %} to the server. It does not run on push. It waits for the `Pytest` workflow to finish, and only fires when that run succeeded on `main`. The deployment itself is a single authenticated `POST` to a webhook endpoint served by the running application.

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

## Workflow name

- **name**: `Deploy on Webhook`

## Trigger

```yaml
on:
  workflow_run:
    workflows: 
      - "Pytest"
    types:
      - completed
```

`workflow_run` chains one workflow onto another. This workflow is scheduled when a run of the workflow *named* `Pytest` completes, whatever its conclusion.

{: .warning-title }
> The link between the two workflows is the name, not the filename
>
> `workflows: ["Pytest"]` matches the `name:` field declared inside `.github/workflows/CI_pytest.yml`.
> Renaming that workflow, or renaming this list entry, breaks the chain silently: no error, no failed run,
> deployments simply stop happening. See the [Testing workflow]({{site.baseurl}}/ci_cd/continuous_integration/testing_workflow).

## The gate

`completed` includes failed runs, so the real gate is the job condition:

```yaml
jobs:
  deploy:
    if: github.event.workflow_run.conclusion == 'success' && github.ref == 'refs/heads/main'
    runs-on: ubuntu-24.04
```

Two conditions must both hold:

- `github.event.workflow_run.conclusion == 'success'`: the test run that triggered this workflow passed. A red test suite never reaches the server.
- `github.ref == 'refs/heads/main'`: only `main` deploys.

If either condition fails, the job is skipped. A skipped job is not a failed job, so a pull request whose tests passed will show this workflow as skipped rather than red.

## Step

{% raw %}
```yaml
- name: Trigger Deployment Webhook
  env:
    WEBHOOK_DOMAIN: ${{ secrets.WEBHOOK_DOMAIN }}
    WEBHOOK_TOKEN: ${{ secrets.WEBHOOK_TOKEN }}
  run: |
    curl -X POST \
      https://${{ secrets.WEBHOOK_DOMAIN }}/webhook/deploy \
      -H "Authorization: Bearer ${{ secrets.WEBHOOK_TOKEN }}"
```
{% endraw %}

GitHub does not have access to the server. It only sends a plain `POST` with the bearer token in the `Authorization` header, and the server does the work.

## Required secrets

| Secret | Purpose |
|:---|:---|
| `WEBHOOK_DOMAIN` | The host that serves the deployment endpoint, without scheme, for example `uvlhub.io` |
| `WEBHOOK_TOKEN` | The bearer token the endpoint checks. It must match the `WEBHOOK_TOKEN` environment variable on the server |

Register them the same way as the Docker Hub secrets: `Settings` then `Secrets and variables` then `Actions` then `New repository secret`.

## The receiving end

The endpoint is provided by the `webhook` feature, at `app/features/webhook/routes.py`:

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

The token comparison is the only authentication, so treat `WEBHOOK_TOKEN` as a production credential. The
token is read from the environment on every request, the comparison runs in constant time through
`hmac.compare_digest`, and if the server has no `WEBHOOK_TOKEN` configured the endpoint refuses every request
with a `503` instead of comparing against an empty value.

`WebhookService.deploy()` then performs the deployment inside the running web container, in this order:

1. Run `scripts/git_update.sh` to pull the new code.
2. Run `pip install -r requirements.txt` to refresh dependencies.
3. Run `flask db upgrade` to apply pending migrations.
4. Append a timestamped entry to `/workspace/deployments.log`.
5. Restart the container through `scripts/restart_container.sh`.

Note that the service needs the Docker CLI and the Docker socket, which is why the `webhook` feature belongs to a Docker based deployment and is declared under `features_dev` in the root `pyproject.toml`:

```toml
[tool.splent]
features_dev = [
    "webhook",
]
```

## Testing the endpoint by hand

You can trigger a deployment without going through GitHub, which is the fastest way to tell whether a failed deployment is a workflow problem or a server problem:

```bash
curl -i -X POST \
  https://<your-domain>/webhook/deploy \
  -H "Authorization: Bearer <your-token>"
```

Expected responses:

- `200 Deployment successful`: the deployment ran.
- `403`: the token does not match the server's `WEBHOOK_TOKEN`.
- `404`: the container named `web_app_container` was not found on the host.
- `405`: you sent a `GET`. The route only accepts `POST`.
- `503` with `{"error": "Webhook token is not configured"}`: the server has no `WEBHOOK_TOKEN` set. Every
  `POST` gets this response, whatever token you send, until the variable is configured.
