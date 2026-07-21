---
layout: default
title: Switching between work environments
parent: Troubleshooting
permalink: /troubleshooting/switching_between_work_environments
---

# Switching between work environments
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

## The `.env` file is what selects the environment

Local, Docker and Vagrant share the same working tree, and each of them expects a different `.env`. The variables
that actually differ are `WORKING_DIR` and `MARIADB_HOSTNAME`:

| Environment | Example file | `WORKING_DIR` | `MARIADB_HOSTNAME` |
|---|---|---|---|
| Local | `.env.local.example` | `""` | `localhost` |
| Docker | `.env.docker.example` | `/workspace/` | `db` |
| Vagrant | `.env.vagrant.example` | `/vagrant/` | `localhost` |

Every Rosemary command builds its paths from `WORKING_DIR`, so a stale value is what produces errors such as
`FileNotFoundError: [Errno 2] No such file or directory: '/workspace/app/features'`. When you move to a different
environment, copy the matching example file first:

```
cp .env.local.example .env
source .env
```

{: .note-title }
> Beware of custom variables
>
> Overwriting `.env` discards the variables contributed by your features. Run `rosemary compose:env` afterwards to
> merge every `.env` file found under `app/features/` back into the root `.env`.

## *bash: .../venv/bin/flask: bad interpreter: No such file or directory*

A virtual environment records the absolute path of the interpreter that created it. If that path does not exist in
the environment you are currently in, every script inside `venv/bin/` fails this way.

Docker and Vagrant are set up so that they no longer collide with your local environment:

- Docker installs the dependencies into the image itself. `docker/images/Dockerfile.dev` does not create a virtual
  environment at all, so nothing of it lands in the bind mount.
- Vagrant creates its environment as `vagrant_venv`, not `venv`, precisely so that it does not overwrite yours
  through the synced folder.

So a broken `venv` today normally means it was created by a different interpreter on your own machine, or it is a
leftover from an older checkout.

### Solution 1: recreate the `venv` folder in local environment

```
rm -r venv
python3.13 -m venv venv
source venv/bin/activate
cp .env.local.example .env
pip install --upgrade pip
pip install -r requirements.txt
pip install -e ./rosemary
```

### Solution 2: use a name for the local environment different from the conventional one

If you want to be extra safe, give your local environment its own name:

```
python3.13 -m venv myenv
source myenv/bin/activate
```

`venv/`, `.venv/` and `vagrant_venv/` are all in `.gitignore`, so remember to add your own name to it if you pick a
different one.

## *error: Cannot update time stamp of directory 'rosemary.egg-info'*

The development container reinstalls Rosemary from inside the bind mount, running as `root`:

```
pip install -e ./rosemary
```

That writes `rosemary/src/rosemary.egg-info/` into your working tree with root ownership. Back on the host, pip
cannot update it. Remove it and reinstall from the environment you are actually using:

```
sudo rm -r rosemary/src/rosemary.egg-info/
pip install -e ./rosemary
```

## Stale bytecode after switching interpreters

`__pycache__` directories and `.pyc` files are also written into the bind mount. They are keyed by interpreter
version, so they are usually harmless, but if you see import errors that do not match the source you are reading,
clear them:

```
rosemary clear:cache
```

This removes the `build` directory and every `__pycache__` directory and `.pyc` file under the project root.
