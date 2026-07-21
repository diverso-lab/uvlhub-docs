---
layout: default
title: Project structure
parent: Architecture
permalink: /architecture/project_structure
nav_order: 2
---

# Project structure
{: .no_toc }

This section provides an overview of the directory and file structure of the project. Each subsection describes the purpose and contents of specific directories and files, highlighting their roles within the overall architecture. Understanding this structure is crucial for effective development, maintenance, and deployment of the application. Below is a detailed explanation of each component in the project.

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

## .github/workflows

This directory contains GitHub Actions workflows. These YAML files define automated actions that run on specific repository events, such as pushes or pull requests.

| File | Workflow name |
|:--|:--|
| `CI_pytest.yml` | Pytest |
| `CI_lint.yml` | Python Lint |
| `CI_commits.yml` | Commits Syntax Checker |
| `CD_dockerhub.yml` | Publish image in Docker Hub |
| `CD_webhook.yml` | Deploy on Webhook |

## app

The main application package. It holds the Flask app factory, the feature loader, the features themselves and the assets and templates that are shared across the whole product.

### app/\_\_init\_\_.py

Defines `create_app(config_name)`, the Flask application factory. It loads configuration through `ConfigManager`, binds the database, registers features, sets up logging and error handlers, and injects the Jinja globals used by the base template.

It also re-exports the framework's SQLAlchemy singleton, so a feature can keep writing `from app import db` and still end up bound to the same instance that `BaseRepository` and `BaseSeeder` operate on.

### app/features

Every unit of functionality lives here as its own Python package, one directory per feature:

```
app/features/
├── auth/
├── dataset/
├── explore/
├── featuremodel/
├── flamapy/
├── hubfile/
├── profile/
├── public/
├── team/
├── webhook/
└── zenodo/
```

A feature is self-contained: its models, repositories, services, routes, forms, templates, assets, seeders and tests all sit inside its own directory. See [HTTP Request]({{site.baseurl}}/architecture/http_request) for what each file inside a feature does.

{: .warning-title }
> Naming
>
> This directory used to be `app/modules/`. The domain word is now *feature*, not *module*, and the same rename applies to the Rosemary commands that operate on them.

### app/feature_loader.py

Discovers and registers features at application start. `register_features(app, env)` walks `app/features/`, keeps only the features declared in `pyproject.toml`, and for each one, in order:

1. Calls `config.inject_config(app)` if the feature defines it, so it can mutate `app.config` before anything else reads it.
2. Imports the conventional submodules `routes`, `models`, `hooks` and `signals`, so any `Blueprint` defined in them becomes discoverable.
3. Calls the feature's `init_feature(app)` lifecycle hook if it defines one.
4. Registers every Flask `Blueprint` found in the feature root or in those submodules, deduplicating by blueprint name.

If neither feature list is declared in `pyproject.toml`, every package found under `app/features/` is loaded.

### app/static

Product-wide static assets: `css`, `js`, `img`, `fonts` and `gifs`. Assets that belong to a single feature live in that feature's own `assets/` directory instead.

### app/templates

Product-wide Jinja templates: `base_template.html` and the error pages `400.html`, `401.html`, `404.html` and `500.html`. Feature-specific templates live under `app/features/<feature>/templates/`.

## conftest.py

The top-level pytest configuration. It sets `SPLENT_APP=app` before importing anything else, so the framework's app loader can resolve `create_app("testing")` without depending on your shell environment, and it re-exports the fixtures shipped by `splent_framework` so every collected test picks them up:

```python
from splent_framework.fixtures.fixtures import (
    clean_database,
    test_app,
    test_client,
    test_client_module,
)
```

Fixtures that only concern one feature belong in `app/features/<feature>/tests/conftest.py`.

## tests

Cross-feature test support that does not belong to any single feature. It currently holds `selenium_support.py`, the helper that resolves the WebDriver and the target host for the end-to-end layer.

Both helpers branch on `WORKING_DIR`. Inside Docker (`WORKING_DIR=/workspace/`), `selenium_support.initialize_driver()` returns a `webdriver.Remote` attached to the Selenium Grid started by `docker/docker-compose.dev.yml`, and `get_host_for_selenium_testing()` returns the URL of the app *as the browser sees it* — the nginx container, not `localhost`, because `localhost` inside the browser container resolves to the browser itself. Run outside Docker, `initialize_driver()` falls back to a local `webdriver.Chrome()` or `webdriver.Firefox()` and the host becomes `http://localhost:5000`.

This module exists because the framework's own Selenium helper builds a local Chrome through `webdriver_manager`, and no browser is installed inside `web_app_container`. Every `test_selenium.py` in the project imports from here:

```python
from tests.selenium_support import close_driver, get_host_for_selenium_testing, initialize_driver
```

## docker

### entrypoints

| Script | Purpose |
|:--|:--|
| `development_entrypoint.sh` | Entrypoint for the web app container in the development environment. |
| `production_entrypoint.sh` | Entrypoint for the web app container in the production environment. |
| `render_entrypoint.sh` | Entrypoint for the web app container in the Render environment. |
| `locust_entrypoint.sh` | Entrypoint for the Locust load testing container. |

### images

| Dockerfile | Purpose |
|:--|:--|
| `Dockerfile.dev` | Development image, with every dependency and configuration needed for development. |
| `Dockerfile.prod` | Production image, optimised for performance and security. |
| `Dockerfile.render` | Image for deploying the application on Render.com. |
| `Dockerfile.webhook` | Production image for the webhook-driven deployment. It adds the Docker client and marks `/workspace` as a safe Git directory so the container can redeploy itself. |
| `Dockerfile.mariadb` | MariaDB image, used to integrate the database into the development or production environment. |
| `Dockerfile.locust` | Image for running load and stress tests with Locust. |

All application images set `WORKDIR /workspace`. Inside a container the project is at `/workspace/`, and `WORKING_DIR=/workspace/` in the environment file reflects that.

### letsencrypt

An empty directory whose contents are gitignored. `docker/docker-compose.prod.ssl.yml` bind-mounts it to `/etc/letsencrypt`, so it is where the certificates issued by Let's Encrypt land. The generation and renewal logic lives in `scripts/ssl_setup.sh` and `scripts/ssl_renew.sh`.

### nginx

Configuration for the NGINX web server, which serves the application and handles HTTP traffic: `nginx.dev.conf`, `nginx.prod.conf`, the templates `nginx.prod.no-ssl.conf.template` and `nginx.prod.ssl.conf.template`, and the `html/` directory with the 502 error pages.

### public

Another empty, gitignored directory. `docker/docker-compose.prod.ssl.yml` bind-mounts it to `/var/www` in both the nginx and the certbot containers, so it is the webroot Certbot writes the ACME challenge files to (`--webroot --webroot-path=/var/www`) while a certificate is being issued.

### Compose files

There is no compose file at the repository root. They all live in `docker/`, so every command has to point at one explicitly:

```
docker compose -f docker/docker-compose.dev.yml up -d
```

| File | Purpose |
|:--|:--|
| `docker-compose.dev.yml` | Development environment. Also brings up the Selenium Grid used by the e2e layer. |
| `docker-compose.prod.yml` | Production environment. |
| `docker-compose.prod.ssl.yml` | Production environment with SSL. |
| `docker-compose.prod.webhook.yml` | Production environment built from `Dockerfile.webhook`, for webhook-driven deployment. |

## vagrant

### Vagrantfile

A specification that describes how to create a virtual machine under specific characteristics. It defines the configuration needed for the development environment, such as the base box, network, shared folders and provisioning scripts.

### *.yml

These files, known as playbooks, are used by Ansible to automate system configuration and management. A playbook is a YAML file containing a series of instructions and tasks that Ansible executes on the target machines. Playbooks automate complex and repetitive tasks, ensuring the environment is configured consistently.

## migrations

Alembic migration files, which allow incremental changes to the database schema in a controlled and reproducible manner. It contains `alembic.ini`, `env.py`, `script.py.mako` and the `versions/` directory with the individual revisions.

## rosemary

The Rosemary CLI package. It is a standard `src`-layout Python package with its own `rosemary/pyproject.toml`, so the code sits at `rosemary/src/rosemary/`:

```
rosemary/
├── pyproject.toml
└── src/
    └── rosemary/
        ├── cli.py
        ├── commands/
        └── templates/
```

Install it in editable mode by pointing pip at the subdirectory, not at the repository root:

```
pip install -e ./rosemary
```

`commands/` holds one module per command and `templates/` holds the Jinja templates that `rosemary feature:create` renders when it scaffolds a new feature.

## scripts

Auxiliary scripts that automate various tasks: `clean_docker.sh`, `git_update.sh`, `init-testing-db.sh`, `restart_container.sh`, `ssl_renew.sh`, `ssl_setup.sh` and `wait-for-db.sh`.

## `.env.<deployment_environment>.example`

These files provide an example of the environment variables needed to run the application. They are used as a reference when setting up an environment: `.env.local.example`, `.env.docker.example`, `.env.docker.production.example` and `.env.vagrant.example`.

The value of `WORKING_DIR` is what tells the code which environment it is in. It is empty for a local install, `/workspace/` under Docker and `/vagrant/` under Vagrant.

## .gitignore

A list of files and directories that Git should ignore. This prevents certain files, such as local configuration, uploads and temporary files, from being included in version control.

## requirements.txt

The pinned list of Python dependencies, installed with `pip`. Every version is pinned exactly. The entry that matters most to the architecture is the framework the product is built on:

```
splent_framework==1.7.0
```

See [splent_framework]({{site.baseurl}}/architecture/splent_framework) for what that package provides.

## pyproject.toml

The root `pyproject.toml` is the single configuration file for the product. There is no `setup.py` and no `.flake8`; both were removed and their settings moved here.

It declares the Python version:

```toml
[project]
name = "uvlhub"
version = "1.0.0"
requires-python = ">=3.13"
```

### The feature contract

`[tool.splent]` declares which features get loaded, and in which environment. It is the single source of truth for feature selection. [Feature selection]({{site.baseurl}}/architecture/feature_selection) documents the resolution rules in full:

```toml
[tool.splent]
features = [
    "auth",
    "dataset",
    "explore",
    "featuremodel",
    "flamapy",
    "hubfile",
    "profile",
    "public",
    "team",
    "zenodo",
]
features_dev = [
    "webhook",
]
features_prod = []
```

`features` is the base list, always loaded. `features_dev` and `features_prod` add entries for one environment only. `app/feature_loader.py` loads the union of `features` and `features_<env>`, where `env` is `prod` when the app is created with the `production` config and `dev` otherwise. To stop a feature from loading, remove it from these lists.

### Formatting and linting

```toml
[tool.black]
line-length = 120
target-version = ["py313"]

[tool.isort]
line_length = 120
profile = "black"

[tool.flake8]
max-line-length = 120
extend-ignore = ["E203", "W503"]
```

Flake8 does not natively read `pyproject.toml`; the `Flake8-pyproject` dependency in `requirements.txt` is what makes the `[tool.flake8]` table apply.

### Testing

`[tool.pytest.ini_options]` sets the collection roots and declares the markers of the testing pyramid:

```toml
[tool.pytest.ini_options]
testpaths = ["app/features", "tests"]
python_files = ["test_*.py"]
filterwarnings = ["ignore::DeprecationWarning"]
markers = [
    "unit: pure unit tests, no Flask app, no database",
    "repository: repository tests against the database (no business logic)",
    "service: service-level tests against the database (orchestration + repos)",
    "integration: HTTP-level integration tests via Flask test client",
    "e2e: browser-driven end-to-end tests (requires the selenium grid)",
    "load: locust load tests (run via `rosemary locust`)",
]
```

Because `python_files` is restricted to `test_*.py`, the per-feature `locustfile.py` is never collected by pytest. Load tests are driven by Locust instead.
