---
layout: default
title: Installation with Docker
parent: Installation
permalink: /docs/installation/installation_with_docker
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
> This manual is intended for a development environment. For a production environment, visit [Deployment]({{site.baseurl}}/docs/deployment).


## Set environment files

First, copy the `.env.docker.example` file to the `.env` file that will be used to set the environment variables.

```
cp .env.docker.example .env
```

## Run the containers

To start containers in development mode, use the `docker-compose.dev.yml` file located in the docker directory. The command will run in the background (`-d`).

```
docker compose -f docker/docker-compose.dev.yml up -d 
```

## See containers in execution

To verify that the containers are running correctly, use the following command:

```
docker ps
```

> {: .highlight }
  **If everything worked correctly, you should see the deployed version of {% include uvlhub.html %} in development at `http://localhost`**

## Down the containers

To download (stop) the containers, use the same `docker-compose.dev.yml` file with the following command:

```
docker compose -f docker/docker-compose.dev.yml down
```