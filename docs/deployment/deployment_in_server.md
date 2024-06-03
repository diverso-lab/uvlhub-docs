---
layout: default
title: Deployment in server
parent: Deployment
permalink: /docs/deployment/server
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

{: .important-title }
> <i class="fa-solid fa-triangle-exclamation"></i> Don't forget to define the variables!
>
> You need to properly define the values of the variables indicated with `<CHANGE_THIS>` in the `.env` file. This is very sensitive and private information. Don't use obvious passwords, use a password generator.

{: .important-title }
> <i class="fa-solid fa-triangle-exclamation"></i> Don't forget your own variables!
>
> If you have been using modules that included their own `.env` file, please note that in production environment neither the Rosemary CLI nor the `rosemary compose:env` command is available for security reasons.
> 
> That means that you have to add to the `.env` file the variables defined by your modules.

## Deploy containers

This process includes building and deploying the services defined in the Docker configuration file for the production environment. To deploy the application to production, run:

```
docker compose -f docker/docker-compose.prod.yml up -d --build
```

> {: .highlight }
  <i class="fa-solid fa-globe"></i> **If everything worked correctly, you should see the deployed version of {% include uvlhub.html %} in development at `http://yourdomain.com`**


## Watchdog available

The production deployment includes a Watchdog container provided by Watchtower ([more info](https://hub.docker.com/r/containrrr/watchtower)). This container is responsible for monitoring changes to Docker images in Docker Hub. When it detects a new version of an image, it automatically updates and restarts the affected containers. This functionality is particularly useful for deploying continuous deployments, ensuring that you are always using the latest version of the software without manual intervention.

{: .warning-title }
> <i class="fa-solid fa-server"></i> Important considerations
>
> - The production environment uses Gunicorn. Gunicorn is a WSGI (Web Server Gateway Interface) HTTP server for Python applications that allows multiple requests to be handled simultaneously in production environments.
> - Rosemary is a development package, so it is not available in production for security reasons.
> - The test database is also not available.
> - The production environment is deployed without any populated test data for security reasons.
> - Debug mode is disabled, so no specific error trace will be shown, only a generic error of type 4xx or 5xx.
