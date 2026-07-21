---
layout: default
title: Deployment in server
parent: Deployment
permalink: /deployment/server
nav_order: 1
---

# Deployment in server
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

{: .important-title }
> <i class="fa-brands fa-docker"></i> Required Docker installation
>
> You need to have Docker and Docker Compose installed on the server where you want to deploy {% include uvlhub.html %} 

## Clone the repo

```
git clone https://www.github.com/diverso-lab/uvlhub
```

## Environment variables

It is necessary to configure the environment variables file in a production environment. These variables are crucial to define specific configurations of the production environment.

```
cp .env.docker.production.example .env
```

The resulting file looks like this:

```
FLASK_APP_NAME="UVLHUB.IO"
FLASK_ENV=production
DOMAIN=<CHANGE_THIS>
MARIADB_HOSTNAME=db
MARIADB_PORT=3306
MARIADB_DATABASE=uvlhubdb
MARIADB_USER=<CHANGE_THIS>
MARIADB_PASSWORD=<CHANGE_THIS>
MARIADB_ROOT_PASSWORD=<CHANGE_THIS>
WEBHOOK_TOKEN=<CHANGE_THIS>
WORKING_DIR=/workspace/
```

Note that `WORKING_DIR` is `/workspace/`. That is the `WORKDIR` of every image under `docker/images/`, and every
path the application and the Rosemary CLI resolve is built from it. Do not change it.

{: .important-title }
> <i class="fa-solid fa-triangle-exclamation"></i> Don't forget to define the variables!
>
> You need to properly define the values of the variables indicated with `<CHANGE_THIS>` in the `.env` file. This is very sensitive and private information. Don't use obvious passwords, use a password generator.

{: .important-title }
> <i class="fa-solid fa-triangle-exclamation"></i> Don't forget your own variables!
>
> If you have been using features that included their own `.env` file, please note that in production environment neither the Rosemary CLI nor the `rosemary compose:env` command is available for security reasons.
> 
> That means that you have to add to the `.env` file the variables defined by your features.

## Choose the features you deploy

The set of features that the application loads is declared in the root
`pyproject.toml` (see [Feature selection]({{site.baseurl}}/architecture/feature_selection), which also
records why `features_prod` is not reached by the shipped production entrypoint):

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

`features` is the base list, always loaded. `features_dev` adds entries for development and testing, `features_prod`
adds entries for production. `app/feature_loader.py` walks `app/features/` and skips any package that is not in the
resulting set. To take a feature out of a deployment, remove its name from these lists.

### The `webhook` feature

`webhook` is a development-only entry. `app/features/webhook/services.py` calls `docker.from_env()` at import time,
which requires the Docker CLI and the Docker socket. Only `docker/images/Dockerfile.dev` and
`docker/images/Dockerfile.webhook` install the CLI, and only the corresponding compose files mount
`/var/run/docker.sock`.

{: .warning-title }
> <i class="fa-solid fa-triangle-exclamation"></i> The feature filter needs `pyproject.toml` inside the image
>
> `app/feature_loader.py` reads `pyproject.toml` from the directory above `app/`, and when it cannot find the file it
> falls back to loading **every** package under `app/features/`. `docker/images/Dockerfile.prod` copies `app/`,
> `migrations/` and `requirements.txt`, but not `pyproject.toml`.
>
> So if you are deploying the prebuilt production image and you do not want the `webhook` feature, delete the
> `app/features/webhook/` directory from your fork as well. Editing `pyproject.toml` alone will not keep it out of
> that image, and the application will refuse to boot with
> `docker.errors.DockerException: Error while fetching server API version`.

## Deploy containers

The production compose files do not build the application. Their `web` service only declares
`image: <your_dockerhub_name>/uvlhub:latest`, so before your first deployment you have to edit
`docker/docker-compose.prod.yml` and replace `<your_dockerhub_name>` with the Docker Hub account the image is
published to. That is the account behind the `DOCKER_USER` secret used by
`.github/workflows/CD_dockerhub.yml`, which pushes `$DOCKER_USER/uvlhub:$TAG` and `$DOCKER_USER/uvlhub:latest`
whenever a GitHub release is published.

With the image name set, deploy the application to production:

```
docker compose -f docker/docker-compose.prod.yml up -d
```

There is no `--build` here: the image is pulled, not built.

This brings up four containers: `web_app_container` (the application, served by Gunicorn on port 5000),
`mariadb_container`, `nginx_web_server_container` (listening on port 80) and `watchtower_container`.

If you want to serve over HTTPS, use the SSL variant instead, which adds Certbot and exposes port 443. Replace
`<your_dockerhub_name>` in `docker/docker-compose.prod.ssl.yml` the same way:

```
docker compose -f docker/docker-compose.prod.ssl.yml up -d
```

If you want deployments to be triggered by the `webhook` feature, use the compose file built for it. This is the
only production compose file with a `build:` section (context `../`, dockerfile `docker/images/Dockerfile.webhook`),
so `--build` belongs on this command and on no other. It bind-mounts the repository at `/workspace` and mounts the
Docker socket:

```
docker compose -f docker/docker-compose.prod.webhook.yml up -d --build
```

{: .highlight }
> <i class="fa-solid fa-globe"></i> **If everything worked correctly, you should see the deployed version of {% include uvlhub.html %} at `http://yourdomain.com`**

## What the entrypoint does

The `web` service runs `docker/entrypoints/production_entrypoint.sh`, which on every start:

1. Waits for the database with `scripts/wait-for-db.sh`.
2. Runs `flask db init` and `flask db migrate` if `migrations/versions` does not exist yet.
3. Applies the schema with `flask db upgrade`, stamping the revision first if the database already had tables but no
   Alembic revision recorded.
4. Starts Gunicorn: `gunicorn --bind 0.0.0.0:5000 app:app --log-level info --timeout 3600`.

Unlike the development entrypoint, it never seeds the database.

## Watchdog available

The production deployment includes a Watchdog container provided by Watchtower ([more info](https://hub.docker.com/r/containrrr/watchtower)). This container is responsible for monitoring changes to Docker images in Docker Hub. When it detects a new version of an image, it automatically updates and restarts the affected containers. This functionality is particularly useful for deploying continuous deployments, ensuring that you are always using the latest version of the software without manual intervention.

It is configured to watch `web_app_container` only, and it polls every 120 seconds. The image it pulls is the one
published by the `Publish image in Docker Hub` workflow (`.github/workflows/CD_dockerhub.yml`), which builds
`docker/images/Dockerfile.prod` whenever a GitHub release is published.

{: .warning-title }
> <i class="fa-solid fa-server"></i> Important considerations
>
> - The production environment uses Gunicorn. Gunicorn is a WSGI (Web Server Gateway Interface) HTTP server for Python applications that allows multiple requests to be handled simultaneously in production environments.
> - Rosemary is a development package, so it is not available in production for security reasons. Only `Dockerfile.dev` runs `pip install -e ./rosemary`.
> - The test database is also not available.
> - The production environment is deployed without any populated test data for security reasons.
> - Debug mode is disabled, so no specific error trace will be shown, only a generic error of type 4xx or 5xx.
