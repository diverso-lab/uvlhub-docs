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

## *rosemary: command not found*

The most likely cause is that Rosemary is not installed in the development environment you are using. Rosemary lives
in its own subproject with its own `pyproject.toml`, so it is installed from `./rosemary`:

```
pip install -e ./rosemary
```

If you run `pip install -e ./` instead, it will fail: the repository root is not an installable package.

## *bash: .../venv/bin/rosemary: cannot execute: required file not found*

This problem occurs because the `venv` folder was created by a different environment than the one you are running
`rosemary` from, so the interpreter the launcher script points at does not exist here.

### Solution 1: Run Rosemary from the original environment

If you installed {% include uvlhub.html %} from a Docker or Vagrant environment, make sure you are using it correctly
from that environment. Visit [Using Rosemary]({{site.baseurl}}/rosemary/using_rosemary) for more info.

### Solution 2: Run Rosemary from local environment

If you have decided to move to a local environment, the `venv` directory is no longer valid, you will have to create
another one. To do this, run:

```
rm -r venv
python3.13 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
pip install -e ./rosemary
```

## *FileNotFoundError: [Errno 2] No such file or directory: '/workspace/app/features'*

Rosemary resolves every path it touches against the `WORKING_DIR` environment variable. This error means
`WORKING_DIR` is set to `/workspace/`, which is the path inside the Docker container, while you are running the
command on your own machine, where that directory does not exist.

### Solution 1: run Rosemary in the correct environment

You must use Rosemary inside the web application container. Visit [Using Rosemary]({{site.baseurl}}/rosemary/using_rosemary#using-rosemary-in-docker-environment) for more info.

### Solution 2: switch the environment variables to local

If you are intentionally switching from a Docker environment to a local environment, you must change the environment
variable settings, because `WORKING_DIR` has to be empty for local runs.

While in a terminal in the local environment, run:

```
cp .env.local.example .env
source .env
```

{: .note-title }
> Beware of custom variables
>
> Be careful, this command will cause the features' own variables to be lost. Remember to run
> `rosemary compose:env` to merge every `.env` file found under `app/features/` back into the root `.env` file.

## *FileNotFoundError: [Errno 2] No such file or directory: '/vagrant/app/features'*

Same cause as above, but with `WORKING_DIR` set to `/vagrant/`: you are running Rosemary locally while the
environment variables are configured for Vagrant.

You must use Rosemary inside the Vagrant virtual machine. Visit [Using Rosemary]({{site.baseurl}}/rosemary/using_rosemary#using-rosemary-in-vagrant-environment) for more info.

## *ModuleNotFoundError: No module named 'app'*

Some Rosemary commands import the application (`db:seed`, `db:reset`, `route:list`, `feature:list`). The `rosemary`
console script is installed into the script directory of the interpreter that installed it, which is outside the
repository: `venv/bin/rosemary` in a local environment, `/usr/local/bin/rosemary` in the development container.
Installed entry points do not put the current directory on `sys.path`, so the `app` package has to be reachable
another way.

From the repository root, export the path explicitly before running the command:

```
export PYTHONPATH=$(pwd)
```

The development Docker image already does this for you by setting `ENV PYTHONPATH=/workspace`.

## *error: Cannot update time stamp of directory 'rosemary.egg-info'*

This is due to a previous editable installation of Rosemary performed from a different working environment than the
current one, typically Docker writing into the bind mount as `root`. The metadata directory now lives next to the
package source. To fix this:

```
sudo rm -r rosemary/src/rosemary.egg-info/
```

Then reinstall from the environment you are actually using:

```
pip install -e ./rosemary
```
