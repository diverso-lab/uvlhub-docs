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
> Don't forget to define the variables!
>
> You need to properly define the values of the variables indicated with `<CHANGE_THIS>` in the `.env` file.


## Deploy containers

This process includes building and deploying the services defined in the Docker configuration file for the production environment. To deploy the application to production, run:

```
docker compose -f docker/docker-compose.prod.yml up -d --build
```

## Watchdog available

El despliegue en producción incluye un contenedor de Watchdog proporcionado por Watchtower ([más información](https://hub.docker.com/r/containrrr/watchtower)). Este contenedor se encarga de monitorear los cambios en las imágenes de Docker en Docker Hub. Cuando detecta una nueva versión de una imagen, automáticamente actualiza y reinicia los contenedores afectados. Esta funcionalidad es particularmente útil para implementar despliegues continuos, asegurando que siempre se esté utilizando la versión más reciente del software sin intervención manual.

## Consideraciones

- El entorno de producción usa Gunicorn. Gunicorn es un servidor HTTP WSGI (Web Server Gateway Interface) para aplicaciones Python que permite manejar múltiples solicitudes simultáneamente en entornos de producción.
- Rosemary es un paquete de desarrollo, así que no está disponible en producción por cuestiones de seguridad.
- La base de datos de test tampoco está disponible.
- El entorno de producción se despliega sin ningún dato populado.