---
layout: default
parent: Managing database
grand_parent: Rosemary CLI
title: Access MariaDB
permalink: /docs/rosemary/managing_database/access_mariadb
nav_order: 4
---

# Access MariaDB
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

## Access to console

To directly use the MariaDB console to execute native SQL statements, use:

```
rosemary db:console
```

This command connects to the MariaDB container using the credentials defined in the `.env` file.

## Exit console

To exit the MariaDB console, type:

```
exit;
```