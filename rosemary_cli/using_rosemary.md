---
layout: default
parent: Rosemary CLI
title: Using Rosemary
permalink: /rosemary/using_rosemary
nav_order: 2
---

# Using Rosemary
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

## Using Rosemary in local environment

To use Rosemary CLI in a local environment, we must activate the Python virtual environment:

```
python3.12 -m venv venv
source venv/bin/activate
```

This will create a `venv` folder. Rosemary is a development package, so we must install packages in editable mode:

```
pip install -e ./
```

## Using Rosemary in Docker environment

To use the Rosemary CLI in Docker environment, you need to be inside the `web_app_container` Docker container. This ensures that Rosemary operates in the correct environment and has access to all necessary files and settings.

First, make sure your Docker environment is running. Then, access the `web_app_container` using the following command:

```
docker exec -it web_app_container /bin/bash
```

You are now ready to use Rosemary's commands.

## Using Rosemary in Vagrant environment

To use Rosemary CLI in Vagrant rosemary, you need to be inside the virtual machine.

First, make sure the machine is booted:

```
cd vagrant
vagrant up
```

Second, you must access the machine

```
vagrant ssh
```

Provisioning the machine already activates the Python virtual environment needed to run Rosemary.

You should see the line `(venv) vagrant@ubuntu-mantic:/vagrant$`. That means you can now use Rosemary along with all its commands.