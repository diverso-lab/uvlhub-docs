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

This happens because it has been deployed in production and the `webhook` module has not been added to the `.moduleignore` file. The `webhook` module uses Docker CLI which is only available in the `Dockerfile.dev` and `Dockerfile.webhook` images.

To fix this, add the following line to the `.moduleignore` file:

```
webhook
```

After that, the containers have to be lifted back into production:

```
docker compose -f docker/docker-compose.prod.yml up -d --build
```

If you are deploying using the SSL option:

```
docker compose -f docker/docker-compose.prod.ssl.yml up -d --build
```