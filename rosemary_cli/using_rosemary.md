---
layout: default
parent: Rosemary CLI
title: Using Rosemary
permalink: /rosemary/using_rosemary
nav_order: 1
---

# Using Rosemary
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

## Where Rosemary lives

Rosemary is not part of the application package. It is a separate, self-contained project inside the repository:

```
rosemary/
├── pyproject.toml
└── src/
    └── rosemary/
        ├── cli.py
        └── commands/
```

Its own `rosemary/pyproject.toml` declares the `rosemary` console script and `requires-python = ">=3.13"`. That is
why it is installed from the `rosemary/` directory and not from the repository root.

## Using Rosemary in local environment

To use the Rosemary CLI in a local environment, create and activate a Python 3.13 virtual environment:

```
python3.13 -m venv venv
source venv/bin/activate
```

This will create a `venv` folder. Install the application dependencies first:

```
pip install --upgrade pip
pip install -r requirements.txt
```

Rosemary is a development package, so install it in editable mode from its own directory:

```
pip install -e ./rosemary
```

{: .warning-title }
> <i class="fa-solid fa-triangle-exclamation"></i> Not `pip install -e ./`
>
> The repository root is not an installable package: there is no `setup.py`, and the root `pyproject.toml` only
> carries project metadata and tool configuration. `pip install -e ./` fails there. The path to install is
> `./rosemary`.

Check that it worked:

```
rosemary info
```

## Using Rosemary in Docker environment

To use the Rosemary CLI in a Docker environment, you need to be inside the `web_app_container` container. This
ensures that Rosemary operates in the correct environment and has access to all necessary files and settings.

First, make sure your Docker environment is running. Then, access the `web_app_container` using the following
command:

```
docker exec -it web_app_container /bin/bash
```

Rosemary is already installed there. The development image installs it at build time, and the development
entrypoint reinstalls it with `pip install -e ./rosemary` from inside the bind mount, so the code you edit on the
host is the code the container runs.

Note that inside the container the working directory is `/workspace`, not `/app`.

You are now ready to use Rosemary's commands.

## Using Rosemary in Vagrant environment

To use the Rosemary CLI in a Vagrant environment, you need to be inside the virtual machine.

First, make sure the machine is booted:

```
cd vagrant
vagrant up
```

Second, you must access the machine:

```
vagrant ssh
```

Provisioning the machine already creates the Python 3.13 virtual environment needed to run Rosemary, and it appends
the activation to `.bashrc`, so the environment is active as soon as you log in.

The virtual environment is called `vagrant_venv`, not `venv`, precisely so that it does not collide with a local
`venv` folder through the synced folder. You should see the `(vagrant_venv)` prefix in your prompt, along with
`/vagrant` as the current directory. That means you can now use Rosemary along with all its commands.

## Listing the available commands

Whatever the environment, this prints every command Rosemary exposes:

```
rosemary --help
```
