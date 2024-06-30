---
layout: default
parent: Managing database
grand_parent: Rosemary CLI
title: Reset database
permalink: /rosemary/managing_database/reset_database
nav_order: 3
---

# Reset database
{: .no_toc }

The `rosemary db:reset` command is a powerful tool for resetting your project's database to its 
initial state. This command deletes all the data in your database, making it ideal for fixing any inconsistencies 
we may have created during development.

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

## Basic Usage

To reset your database and clear all table data except for migration records, run:

```
rosemary db:reset
```

The `rosemary db:reset` command also clears the uploads directory as part of the reset process, ensuring that any files 
uploaded during development or testing are removed.

## Clear migrations

If you need to completely rebuild your database from scratch, including removing all migration history and starting
fresh, you can use the `--clear-migrations` option:

``` 
rosemary db:reset --clear-migrations
```

{: .warning-title }
> Be careful! This command will...
>
> - Delete all data from the database, including the migration history.
> - Clear the migrations directory.
> - Initialize a new set of migrations.
> - Apply the migrations to rebuild the database schema.