---
layout: default
title: Getting started
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

You can start your fantastic development with uvlhub by cloning our official repository.

```
git clone https://github.com/diverso-lab/uvlhub.git
cd uvlhub
```

## Environment variables

To create an `.env` file according to a basic template, run:

```
cp .env.example .env
```

## Deploy in develop

To deploy the software under development environment, run:

```
docker compose -f docker-compose.dev.yml up -d 
```

This will apply the migrations to the database and run the Flask application. 

> {: .highlight }
  **If everything worked correctly, you should see the deployed version of UVLHub in development at `http://localhost`.**

