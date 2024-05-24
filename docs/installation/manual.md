---
layout: default
title: Manual installation
parent: Installation
permalink: /docs/installation/manual_installation
nav_order: 1
---

# Manual installation

## Update the system

```
sudo apt update -y
sudo apt upgrade -y
```

## Install MariaDB

### Install official package

MariaDB is available in the official Ubuntu repositories, so you can easily install it with apt:

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

###  Configure Databases and Users

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