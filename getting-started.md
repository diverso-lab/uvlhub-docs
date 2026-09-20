---
layout: default
title: Getting started
permalink: /getting-started
nav_order: 2
---

# Getting started
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

{: .important }
For development deployment, the use of [Docker](https://www.docker.com/) is recommended. 

## Clone repo

{: .important-title }
> <i class="fa-solid fa-graduation-cap"></i> Are you a student of Configuration Evolution and Management (EGC)?
>
> The course works on its own copy of the project, `github.com/EGCETSII/uvlhub`, which you fork as
> `uvlhub_practicas`. Clone your fork, not the repository below: the two have diverged and the practicals are
> written against the course copy.
> ```
> git clone https://github.com/<YOUR_GITHUB_USER>/uvlhub_practicas.git
> cd uvlhub_practicas
> ```

You can start your fantastic development with {% include uvlhub.html %} by cloning our official repository.

```
git clone https://github.com/diverso-lab/uvlhub.git
cd uvlhub
```

## Environment variables

To create an `.env` file according to a basic template, run:

```
cp .env.docker.example .env
```

## Deploy in develop

To deploy the software under development environment, run:

```
docker compose -f docker/docker-compose.dev.yml up -d 
```

This will apply the migrations to the database, seed it with test data the first time it comes up empty, and
run the Flask application. 

> {: .highlight }
  **If everything worked correctly, you should see the deployed version of {% include uvlhub.html %} in development at `http://localhost`**

