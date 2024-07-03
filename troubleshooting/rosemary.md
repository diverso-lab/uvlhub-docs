---
layout: default
title: Rosemary
parent: Troubleshooting
permalink: /troubleshooting/rosemary
---

# Rosemary
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

## *rosemary: order not found | no se encontró la orden*

The most likely cause is that Rosemary is not installed in the development environment you are using. To do this, run:

```
pip install -e ./
```

## *bash: .../venv/bin/rosemary: cannot be executed: the required file could not be found | no se puede ejecutar: no se ha encontrado el fichero requerido*

This problem occurs because the `venv` environment is installed by Docker or Vagrant and you are running `rosemary` in a different environment than the one it was created in:

### Solution 1: Run Rosemary from the original environment.

If you installed {% include uvlhub.html %} from a Docker or Vagrant environment, make sure you are using it correctly from that environment. Visit [Using Rosemary]({{site.baseurl}}/rosemary/using_rosemary) for more info.

### Solution 2: Run Rosemary from local environment

If you have decided to move to a local environment, the `venv` directory is no longer valid, you will have to create another one. To do this, run:

```
python -m venv venv
source venv/bin/activate
source .env
```

## *FileNotFoundError: [Errno 2] No such file or directory: '/app/app/modules'*

This error occurs when you are running Rosemary locally but the development environment is configured in Docker.

### Solution 1: run Rosemary in the correct environment

You must use Rosemary inside the web application container. Visit [Using Rosemary]({{site.baseurl}}/rosemary/using_rosemary#using-rosemary-in-docker-environment) for more info.

### Solution 2: technological limitations

If you are intentionally switching from a Docker environment to a local environment (for example, to run tests with Selenium), you must change the environment variable settings.

While in a terminal in the local environment, run:

```
cp .env.local.example .env
source .env
```

{: .note-title }
> Beware of custom variables
>
> Be careful, this command will cause the modules own variables to be lost. Remember to run `rosemary compose:env` to generate the final `env` file.

## *FileNotFoundError: [Errno 2] No such file or directory: '/vagrant/app/modules'*

This error occurs when you are running Rosemary locally but the development environment is configured in Vagrant.

You must use Rosemary inside the Vagrant virtual machine. Visit [Using Rosemary]({{site.baseurl}}/rosemary/using_rosemary#using-rosemary-in-vagrant-environment) for more info.
