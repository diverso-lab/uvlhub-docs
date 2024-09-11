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
> Python version 3.12 or higher is recommended.

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
> git clone git@github.com:<YOUR_GITHUB_USER>/uvlhub.git
> cd uvlhub
> ```

You can clone the original repo with the HTTPS method:

```
git clone https://github.com/diverso-lab/uvlhub.git
cd uvlhub
```

## Install MariaDB

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

### Ignore `webhook` module

The `webhook` module only makes sense in a deployment using Docker and in a pre-production environment. To avoid problems, we indicate that this module should be
ignored in the initial loading of modules by appending the name to the `.moduleignore` file:

```
echo "webhook" > .moduleignore
``` 

## Install dependencies

### Creates and activate a virtual environment

```
sudo apt install python3.12-venv
python3.12 -m venv venv
source venv/bin/activate
```

### Install Python dependencies

`Pip` is the package manager for Python. Its main function is to facilitate the installation, upgrade and uninstallation of Python packages (libraries or modules). It is important to update `pip` because some newer versions of packages require an updated version of pip in order to be installed correctly.

```
pip install --upgrade pip
pip install -r requirements.txt
```

### Install Python dependencies in editable mode (Rosemary)

`Rosemary` is a CLI (Command Line Interface) tool developed to facilitate project management and development tasks ([more information](/rosemary/ "Title")) . It's a development package and it's not available in the `pypi` package manager, we have to install it manually using the `setup.py` file in the root. 
Since we are developers, it would be a pain to reinstall `Rosemary` every time we make a change. Therefore, we use the `-e` flag to install it in editable mode so that any changes to the `Rosemary` code will be detected by the system and the configuration will be reloaded in real time.

```
pip install -e ./
```

To check that `Rosemary` has been installed correctly, try running this command. It should list all available CLI commands:

```
rosemary
```

## Run app



### Apply migrations

We have already created the database, but it is empty! We need to create the tables and their relationships. We can make use of migrations:

```
flask db upgrade
```

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
>`--host=0.0.0.0.0`: **This flag specifies the IP address on which Flask will listen for requests**. By default, Flask listens on `127.0.0.1` (localhost), which means it is only accessible from the machine it is running on. 
>If you specify `0.0.0.0`, Flask will be available to any external connection, allowing the application to be accessible from any device on the network.
>
>`--reload`: **Enables automatic reload mode**. Flask will automatically restart the server if it detects changes to your application files. This is especially useful in development, as it allows you to see the changes > without having to stop and restart the server every time you update the code.
>
>`--debug`: **Enables debug mode**. When debug mode is enabled, Flask will display detailed error information in the browser if an exception occurs.

> {: .highlight }
  **If everything worked correctly, you should see the deployed version of {% include uvlhub.html %} in development at `http://localhost:5000`**