---
layout: default
title: Manual installation
parent: Installation
permalink: /installation/manual_installation
nav_order: 1
---

# Manual installation
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

{: .important-title }
> <i class="fa-brands fa-python"></i> Python version
>
> Python 3.13 is required. The root `pyproject.toml` declares `requires-python = ">=3.13"`, and the
> project will not install on an older interpreter.

{: .warning-title }
> <i class="fa-brands fa-ubuntu"></i> Ubuntu-only support
>
> This tutorial is intended for use on Ubuntu 22.04 LTS or higher.

## Update the system

```
sudo apt update -y
sudo apt upgrade -y
```

## Clone the repo

{: .important-title }
> <i class="fa-solid fa-graduation-cap"></i> Are you a student of Configuration Evolution and Management (EGC)?
>
> Remember that you have to clone your fork from the subject fork instead of the official one.
> ```
> git clone git@github.com:<YOUR_GITHUB_USER>/uvlhub_practicas.git
> cd uvlhub_practicas
> ```

You can clone the original repo with the HTTPS method:

```
git clone https://github.com/diverso-lab/uvlhub.git
cd uvlhub
```

## Install MariaDB

{: .important-title }
> <i class="fa-solid fa-desktop"></i> Are you a student of Configuration Evolution and Management (EGC)?
>
> If you use the VM for the EGC course, you can skip this step.

We need a relational database for our application. We will use MariaDB ([more information](https://mariadb.org/ "Title")) 

### Install official package

MariaDB is available in the official Ubuntu repositories, so you can easily install it with `apt`:

```
sudo apt install mariadb-server -y
```

### Start the MariaDB service

We need to start the MariaDB service to work with the database.

```
sudo systemctl start mariadb
```

### Configure MariaDB

After installing MariaDB, it is recommended to run the security script to perform some initial configurations:

```
sudo mysql_secure_installation
```

Here we detail the default values that must be entered for a successful installation:

```
- Enter current password for root (enter for none): (enter)
- Switch to unix_socket authentication [Y/n]: `y`
- Change the root password? [Y/n]: `y`
    - New password: `uvlhubdb_root_password`
    - Re-enter new password: `uvlhubdb_root_password`
- Remove anonymous users? [Y/n]: `y`
- Disallow root login remotely? [Y/n]: `y` 
- Remove test database and access to it? [Y/n]: `y`
- Reload privilege tables now? [Y/n] : `y`
```

###  Configure databases and users

To configure the database, we are going to use the MariaDB command console:

```
sudo mysql -u root -p
```

Use `uvlhubdb_root_password` as root password.

```
CREATE DATABASE uvlhubdb;
CREATE DATABASE uvlhubdb_test;
CREATE USER 'uvlhubdb_user'@'localhost' IDENTIFIED BY 'uvlhubdb_password';
GRANT ALL PRIVILEGES ON uvlhubdb.* TO 'uvlhubdb_user'@'localhost';
GRANT ALL PRIVILEGES ON uvlhubdb_test.* TO 'uvlhubdb_user'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

## Configure app environment

### Environment variables

We need some environment variables for the connection to the database and the other elements to work properly. 
To do this, we can either write a `.env` file in the root or use a base template:

```
cp .env.local.example .env
```

### Select the features to load

The set of features the application loads is declarative. It lives in the root `pyproject.toml`, under
`[tool.splent]`:

```toml
[tool.splent]
features = [
    "auth",
    "dataset",
    "explore",
    "featuremodel",
    "flamapy",
    "hubfile",
    "profile",
    "public",
    "team",
    "zenodo",
]
features_dev = [
    "webhook",
]
features_prod = [
    "webhook",
]
```

`features` is the base list and is loaded in every environment. `features_dev` adds entries only when the app
runs in the development environment (which also covers testing), and `features_prod` only in production.
`app/feature_loader.py` reads these lists on start-up and registers the blueprints of each selected feature.

`webhook` is declared in both environment lists: development needs it for its test suite and
production serves it for the continuous-deployment pipeline, guarded by `WEBHOOK_TOKEN`. A feature
declared in only one list is loaded only there — that is the mechanism to reach for when you add a
genuinely environment-specific feature.

{: .warning-title }
> <i class="fa-solid fa-plug"></i> `webhook` on a machine without Docker
>
> `app/features/webhook/services.py` calls `docker.from_env()` at import time, so the feature needs a reachable
> Docker daemon. If you are installing manually on a machine that does not run Docker, remove `"webhook"` from
> both `features_dev` and `features_prod` in the root `pyproject.toml` before starting the app.

## Install dependencies

### Install Python 3.13

Ubuntu 22.04 and 24.04 do not ship Python 3.13 in their default repositories, so add the deadsnakes PPA first.
This is exactly what the Vagrant provisioning does:

```
sudo apt install -y software-properties-common
sudo add-apt-repository -y ppa:deadsnakes/ppa
sudo apt update -y
sudo apt install -y python3.13 python3.13-venv
```

### Create and activate a virtual environment

```
python3.13 -m venv venv
source venv/bin/activate
```

### Install Python dependencies

`Pip` is the package manager for Python. Its main function is to facilitate the installation, upgrade and uninstallation of Python packages (libraries or modules). It is important to update `pip` because some newer versions of packages require an updated version of pip in order to be installed correctly.

```
pip install --upgrade pip
pip install -r requirements.txt
```

This also brings in `splent_framework`, the PyPI package that provides the base classes the features build on
(`BaseService`, `BaseRepository`, `BaseSeeder`, `BaseBlueprint`, and friends). It is pinned in
`requirements.txt` like any other dependency, so there is nothing extra to install.

### Install Rosemary in editable mode

`Rosemary` is a CLI (Command Line Interface) tool developed to facilitate project management and development
tasks ([more information]({{site.baseurl}}/rosemary "Title")). It is a development package, it is not published
on PyPI, and it is a separate distribution from the application: its source lives in `rosemary/src/rosemary/`
and it is built from its own `rosemary/pyproject.toml`. That is why you install it by pointing pip at the
`rosemary` directory and not at the root of the repository.

Since we are developers, it would be a pain to reinstall `Rosemary` every time we make a change. Therefore, we
use the `-e` flag to install it in editable mode so that any changes to the `Rosemary` code are picked up
immediately, with no reinstall.

```
pip install -e ./rosemary
```

### Put the project root on the import path

Several `Rosemary` commands import the application package. `rosemary/src/rosemary/commands/db_reset.py`
does `from app import create_app, db` among its top-level imports, and `rosemary/src/rosemary/cli.py` imports every command module
when it builds the command group, so that import runs on every invocation. An installed console script is
executed without the current directory on `sys.path`, so a bare `rosemary` fails with
`ModuleNotFoundError: No module named 'app'` unless you make the project root importable:

```
export PYTHONPATH=$(pwd)
```

Run this from the root of the repository. It only lasts for the current shell, so re-export it in every new
terminal, or append the same line to `venv/bin/activate` so activating the virtual environment sets it for you.

The Docker image solves the same problem with `ENV PYTHONPATH=/workspace` in `docker/images/Dockerfile.dev`;
a manual installation has no equivalent, so this step is on you.

To check that `Rosemary` has been installed correctly, try running this command. It should list all available CLI commands:

```
rosemary
```

## Run app

Run every command below from the root of the repository, with the virtual environment active. Flask discovers
the application automatically through the `app` package, so you do not need to set `FLASK_APP`.

### Apply migrations

We have already created the database, but it is empty! We need to create the tables and their relationships. We can make use of migrations.

On a fresh clone this is the only command you need:

```
flask db upgrade
```

{: .warning-title }
> <i class="fa-solid fa-database"></i> `rosemary db:reset` is a recovery tool, not part of a first install
>
> If you have previously run this project and the local database is in a bad state, `rosemary db:reset` can
> get you back to a clean slate. Understand what it does before running it:
>
> - it deletes the data from every table,
> - it stamps the alembic revision to `head`,
> - it clears the contents of the `uploads/` directory, deleting every uploaded dataset. This happens on every
>   run, with or without any flag.
>
> It does **not** remove the migration structure. That is what `--clear-migrations` adds, and that flag goes
> much further: it runs `shutil.rmtree()` on the `migrations/` directory, which is tracked in git and ships
> revision `001`, and then regenerates it from the models with `flask db init`, `flask db migrate` and
> `flask db upgrade`.
>
> ```
> rosemary db:reset --clear-migrations
> ```
>
> Because it runs those three commands itself, there is nothing to follow it up with. Do not run it on a fresh
> clone: you would delete committed repository content, starting with `migrations/versions/001.py`.

### Populate database

It is possible to create test data so that the system deployed in development has a minimum of navigability without the need to create the entities ourselves.

```
rosemary db:seed
```

### Run development Flask server

We run our application using a Flask developer server. By default, this server starts the app on port `5000`. 

```
flask run --host=0.0.0.0 --reload --debug
```

{: .important-title }
> <i class="fa-solid fa-book"></i> What is this?
>
>Each of the flags (`--host`, `--reload`, `--debug`) has a specific function when running a Flask application.
>
>`--host=0.0.0.0`: **This flag specifies the IP address on which Flask will listen for requests**. By default, Flask listens on `127.0.0.1` (localhost), which means it is only accessible from the machine it is running on. 
>If you specify `0.0.0.0`, Flask will be available to any external connection, allowing the application to be accessible from any device on the network.
>
>`--reload`: **Enables automatic reload mode**. Flask will automatically restart the server if it detects changes to your application files. This is especially useful in development, as it allows you to see the changes > without having to stop and restart the server every time you update the code.
>
>`--debug`: **Enables debug mode**. When debug mode is enabled, Flask will display detailed error information in the browser if an exception occurs.

> {: .highlight }
  **If everything worked correctly, you should see the deployed version of {% include uvlhub.html %} in development at `http://localhost:5000`**