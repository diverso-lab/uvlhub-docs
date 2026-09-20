---
layout: default
title: Installation with Docker
parent: Installation
permalink: /installation/installation_with_docker
nav_order: 2
---

# Installation with Docker
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

{: .important-title }
> <i class="fa-brands fa-docker"></i> Required Docker installation
>
> You need to have Docker and Docker Compose installed on the machine where you want to deploy {% include uvlhub.html %} 

{: .note-title }
> <i class="fa-solid fa-code"></i> Only for a development environment
>
> This manual is intended for a development environment. For a production environment, visit [Deployment]({{site.baseurl}}/deployment).


## Set environment files

First, copy the `.env.docker.example` file to the `.env` file that will be used to set the environment variables.

```
cp .env.docker.example .env
```

## Run the containers

{: .warning-title }
> <i class="fa-brands fa-docker"></i> Did you bring this stack up before September 2026?
>
> The development Compose project is now named `uvlhub`; it used to take the name `docker` from its folder. If you
> still have containers from the old name, the first `up` fails with `Conflict. The container name
> "/web_app_container" is already in use`. Remove the old stack first (this also leaves its database volume,
> `docker_db_data`, unused; the new stack seeds a fresh one):
>
> ```
> docker compose -f docker/docker-compose.dev.yml -p docker down
> ```

To start containers in development mode, use the `docker-compose.dev.yml` file located in the docker directory. The command will run in the background (`-d`).

```
docker compose -f docker/docker-compose.dev.yml up -d 
```

The dev stack brings up six containers:

| Container | Service | What it is |
|---|---|---|
| `web_app_container` | `web` | The Flask application, built from `docker/images/Dockerfile.dev` |
| `mariadb_container` | `db` | MariaDB, published on port `3306` |
| `nginx_web_server_container` | `nginx` | The reverse proxy in front of the app, published on port `80` |
| `selenium_hub_container` | `selenium-hub` | Selenium Grid hub, on port `4444` |
| `selenium_chrome_container` | `selenium-chrome` | Chrome node for the end-to-end tests |
| `selenium_firefox_container` | `selenium-firefox` | Firefox node for the end-to-end tests |

The project root is bind-mounted into the `web` container at `/workspace`, which is also its working directory,
so your edits are picked up without rebuilding. On start-up, the entrypoint installs `rosemary` in editable
mode, waits for the database, applies the migrations and, if the database is empty, seeds it with test data
before starting the Flask development server.

## See containers in execution

To verify that the containers are running correctly, use the following command:

```
docker ps
```

> {: .highlight }
  **If everything worked correctly, you should see the deployed version of {% include uvlhub.html %} in development at `http://localhost`**

## Down the containers

To bring down (stop) the containers, use the same `docker-compose.dev.yml` file with the following command:

```
docker compose -f docker/docker-compose.dev.yml down
```

## Down the containers (removing also volumes)

The above command removes the containers but not the volumes. This can be problematic in the case of MariaDB, which continues saving the previous configuration and will give problems if we want to load a different configuration.

To stop the containers and remove the volumes, we will use the `-v` flag:

```
docker compose -f docker/docker-compose.dev.yml down -v
```

## Reload configuration

If any `Dockerfile` or `docker-compose.*.yml` file has been modified, it is necessary to rebuild the images with the `--build` flag. To do this, execute:

```
docker compose -f docker/docker-compose.dev.yml up -d --build
```
