---
layout: default
grand_parent: CI/CD
parent: Continuous integration
title: Testing workflow
permalink: /ci_cd/continuous_integration/testing_workflow
nav_order: 1
---


# Testing workflow
{: .no_toc }

{: .important-title }
>
> Path to file [(view file on GitHub)](https://github.com/diverso-lab/uvlhub/blob/main/.github/workflows/CI_pytest.yml)
> 
> The original file is located at the following path:
>
> ```
> .github / workflows / CI_pytest.yml 
> ```

This GitHub Actions workflow runs the automated test suite of {% include uvlhub.html %} on every push and pull request that targets `main`. It starts a MariaDB service container, installs the Python dependencies, installs the `rosemary` CLI in editable mode and runs `pytest` over the feature tree.

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

## Workflow name

- **name**: `Pytest`

{: .warning-title }
> Do not rename this workflow
>
> The deployment workflow `CD_webhook.yml` chains off this one through a `workflow_run` trigger that matches
> the workflow by its name:
>
> ```yaml
> on:
>   workflow_run:
>     workflows:
>       - "Pytest"
> ```
>
> If you rename the `Pytest` workflow, deployments silently stop firing.

## Triggers

```yaml
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
```

The workflow only runs for `main`. A push to a feature branch does not run the tests; the tests run when the pull request that targets `main` is opened or updated, and again when the merge lands on `main`.

## Job

- **pytest**: runs on `ubuntu-24.04`.

The runner image is pinned to an explicit Ubuntu version rather than `ubuntu-latest`, so a new runner image release cannot change the environment underneath you.

## Environment variables

The job declares the database configuration once at job level, and the service container reuses it through `{% raw %}${{ env.* }}{% endraw %}`:

| Variable | Value |
|:---|:---|
| `MARIADB_ROOT_PASSWORD` | `uvlhub_root_password` |
| `MARIADB_DATABASE` | `uvlhubdb_test` |
| `MARIADB_TEST_DATABASE` | `uvlhubdb_test` |
| `MARIADB_USER` | `uvlhub_user` |
| `MARIADB_PASSWORD` | `uvlhub_password` |
| `MARIADB_HOSTNAME` | `127.0.0.1` |
| `MARIADB_PORT` | `3306` |
| `FLASK_ENV` | `testing` |

`FLASK_ENV: testing` makes the application read `MARIADB_TEST_DATABASE`, so the tests never touch a development database.

## Service container

A MariaDB container is started alongside the job:

{% raw %}
```yaml
services:
  mariadb:
    image: mariadb:12.0.2
    env:
      MARIADB_ROOT_PASSWORD: ${{ env.MARIADB_ROOT_PASSWORD }}
      MARIADB_DATABASE: ${{ env.MARIADB_DATABASE }}
      MARIADB_USER: ${{ env.MARIADB_USER }}
      MARIADB_PASSWORD: ${{ env.MARIADB_PASSWORD }}
    ports:
      - 3306:3306
    options: >-
      --health-cmd="mariadb-admin ping -u root -p$MARIADB_ROOT_PASSWORD"
      --health-interval=10s
      --health-timeout=5s
      --health-retries=3
```
{% endraw %}

The health check uses `mariadb-admin`, which is the MariaDB client binary. The job does not start running steps until the health check passes, so the database is ready before the first test connects.

## Steps

### 1. Checkout

```yaml
- name: Checkout
  uses: actions/checkout@v5
```

### 2. Set up Python

```yaml
- name: Set up Python
  uses: actions/setup-python@v6
  with:
    python-version: '3.13'
```

Python 3.13 is not optional here. The root `pyproject.toml` declares `requires-python = ">=3.13"` and `splent_framework` requires it.

### 3. Install dependencies

```yaml
- name: Install dependencies
  run: |
    python -m pip install --upgrade pip
    pip install -r requirements.txt
    pip install -e ./rosemary
```

- `requirements.txt` pins the application dependencies, including `splent_framework`, which provides the base classes the features import.
- `pip install -e ./rosemary` installs the CLI from `rosemary/`, which has its own `rosemary/pyproject.toml`. The path is `./rosemary`, not `./`.

### 4. Run tests

```yaml
- name: Run Tests
  run: pytest app/features/ --ignore-glob='*selenium*'
```

That is the whole test step. There is no separate environment preparation step: the environment variables are already declared at job level, so `pytest` inherits them.

You can run exactly the same command locally, from inside `web_app_container`, where the dependencies are installed and MariaDB is reachable:

```bash
docker exec -it web_app_container pytest app/features/ --ignore-glob='*selenium*'
```

## What actually runs in CI

Tests live next to the feature that they exercise, under `app/features/<feature>/tests/`. Each pytest module declares its layer with a module-level marker, for example:

```python
pytestmark = pytest.mark.integration
```

The markers themselves are declared in the root `pyproject.toml` under `[tool.pytest.ini_options]`.

| File | Marker | Runs in CI |
|:---|:---|:---|
| `test_unit.py` | `unit` | Yes |
| `test_repository.py` | `repository` | Yes |
| `test_service.py` | `service` | Yes |
| `test_integration.py` | `integration` | Yes |
| `test_selenium.py` | `e2e` | No, excluded by `--ignore-glob='*selenium*'` |
| `locustfile.py` | none (Locust, not pytest) | No, not matched by `python_files` |

Browser-driven tests are excluded because they need a running Selenium Grid. Locustfiles are not pytest modules at all: they define Locust `HttpUser` and `TaskSet` classes, and `python_files = ["test_*.py"]` means `pytest` never collects them, so they carry no marker. The `load` marker is declared in `pyproject.toml` but is not applied to anything. Both layers are run on demand instead. See [Testing]({{site.baseurl}}/rosemary/testing) for how to run those layers locally.

## Selecting a single layer

Because every pytest module carries a marker, you can narrow a CI failure locally without editing files:

```bash
docker exec -it web_app_container pytest app/features/ -m unit
docker exec -it web_app_container pytest app/features/ -m "repository or service"
docker exec -it web_app_container pytest app/features/dataset/tests/test_integration.py
```
