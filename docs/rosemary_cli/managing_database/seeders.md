---
layout: default
parent: Managing database
grand_parent: Rosemary CLI
title: Seeders
permalink: /docs/rosemary/managing_database/seeders
nav_order: 2
---

# Seeders
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

## Basic Usage

It is possible to populate the database with predefined test data. It is very useful for testing certain
that require existing data.

### Populate from all modules

To populate all test data of all modules, run:

```
rosemary db:seed
```

### Populate from specific module

If we only want to popularize the test data of a specific module, run:

```
rosemary db:seed <module_name>
```

Replace `<module_name>` with the name of the module you want to populate 
(for example, `auth` for the authentication module).

## Reset database before populating

If you want to make sure that the database is in a clean state before populating it with test data, 
you can use the `--reset` flag. This will reset the database to its initial state before running the seeders:

### Reset all modules test data

```
rosemary db:seed --reset
```

### Reset test data of specific module

You can also combine the `--reset` flag with a module specification if you want to reset the database before populating 
only the test data of a specific module:

```
rosemary db:seed <module_name> --reset
```