---
layout: default
title: Docker
parent: Troubleshooting
permalink: /troubleshooting/docker
---

# Docker
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

## *Error response from daemon: driver failed programming external connectivity on endpoint mariadb_container (XXX): Error starting userland proxy: listen tcp4 0.0.0.0:3306: bind: address already in use*

This occurs because there is already a process on port 3306 (typically because MariaDB has been installed manually).

### Identify the process using port 3306

```
sudo lsof -i :3306
```

With this we find out the `PID` identifier of the process running on 3306

### Kill process

```
sudo kill -9 <PID>
```

### Disable MariaDB

If you have installed {% include uvlhub.html %} manually and you are not going to use this deployment anymore, it is convenient to disable the MariaDB process:

```
sudo systemctl stop mariadb
sudo systemctl disable mariadb
```

## *docker.errors.DockerException: Error while fetching server API version: ('Connection aborted.', FileNotFoundError(2, 'No such file or directory'))*

This is the `webhook` feature failing to import. `app/features/webhook/services.py` calls `docker.from_env()` at
module level, so the exception is raised while the feature is being registered and the application never finishes
booting.

That call needs two things the plain production container does not have: the Docker CLI, which is installed only in
`docker/images/Dockerfile.dev` and `docker/images/Dockerfile.webhook`, and the Docker socket bind-mounted at
`/var/run/docker.sock`.

### How features are selected

There is no `.moduleignore` file any more, and nothing reads one. Which features get loaded is declared in the root
`pyproject.toml` (see [Feature selection]({{site.baseurl}}/architecture/feature_selection)):

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

`app/feature_loader.py` walks `app/features/`, and loads a feature only if it appears in `features` or in the list
for the current environment (`features_dev` or `features_prod`). `webhook` is deliberately a development-only entry.

{: .warning-title }
> <i class="fa-solid fa-triangle-exclamation"></i> The filter needs `pyproject.toml` to be present
>
> `app/feature_loader.py` reads `pyproject.toml` from the directory above `app/`. If the file is not there, it falls
> back to loading **every** package it finds under `app/features/`. The production images
> (`Dockerfile.prod`, `Dockerfile.render`) copy `app/`, `migrations/` and `requirements.txt`, but not
> `pyproject.toml` — so inside those images the declarative filter is inactive and `webhook` is imported.

### Solution 1: deploy with the webhook compose file

If you want the webhook-driven deployment, use the compose file that was built for it:

```
docker compose -f docker/docker-compose.prod.webhook.yml up -d --build
```

It builds `docker/images/Dockerfile.webhook`, which installs the Docker CLI, bind-mounts the repository at
`/workspace` and mounts `/var/run/docker.sock` into the container. With those in place `docker.from_env()`
succeeds. This is the only production compose file with a `build:` section, which is why `--build` appears here.

### Solution 2: drop the feature from your deployment

If you do not need continuous deployment through the webhook, remove `"webhook"` from `features_dev` in
`pyproject.toml` *and* delete `app/features/webhook/` from your fork. Removing it from `pyproject.toml` alone is not
enough for the prebuilt production image, for the reason explained in the warning above.

After that, bring the containers back up. These compose files pull the image instead of building it, so there is no
`--build`:

```
docker compose -f docker/docker-compose.prod.yml up -d
```

If you are deploying using the SSL option:

```
docker compose -f docker/docker-compose.prod.ssl.yml up -d
```

Both files ship with the placeholder `image: <your_dockerhub_name>/uvlhub:latest`. If you have not replaced it yet,
see [Deployment in server]({{site.baseurl}}/deployment/server).