---
layout: default
title: Manual installation
parent: Installation
permalink: /docs/installation/manual_installation
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

```
git clone https://github.com/diverso-lab/uvlhub.git
cd uvlhub
```

## Install MariaDB

### Install official package

MariaDB is available in the official Ubuntu repositories, so you can easily install it with `apt`:

```
sudo apt install mariadb-server -y
```

### Start the MariaDB service

```
sudo systemctl start mariadb
```

### Configure MariaDB

After installing MariaDB, it is recommended to run the security script to perform some initial configurations:

```
sudo mysql_secure_installation
```

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

Using `uvlhubdb_root_password` as root password:

```
sudo mysql -u root -p
```

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

### Creates and activate a virtual environment

```
python3 -m venv venv
source venv/bin/activate
```

### Install Python dependencies

```
pip install --upgrade pip
pip install -r requirements.txt
```

### Install Python dependencies in editable mode


```
pip install -e ./
```

## Run app

### Environment variables

```
cp .env.local.example .env
```

### Apply migrations

```
rosemary db:migrate
```

### Popular database

```
rosemary db:seed
```

### Boot development Flask server

```
flask run --host=0.0.0.0 --reload --debug
```

> {: .highlight }
  **If everything worked correctly, you should see the deployed version of {% include uvlhub.html %} in development at `http://localhost:5000`**