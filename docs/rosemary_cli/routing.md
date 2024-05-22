---
layout: default
parent: Rosemary CLI
title: Routing
permalink: /docs/rosemary/routing
nav_order: 4
---

# Routing
{: .no_toc }

The rosemary command `route:list` allows you to list all the routes available in the project. This command is useful for getting a quick overview of available endpoints and their corresponding HTTP methods.

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}



## List all routes

To list all the routes of all the modules, run:

```
rosemary route:list
```

## Group routes by module

To get a grouped view of the routes by module, you can use the `--group` option. This is especially useful 
for applications with a complex modular structure, as it allows you to quickly see how the routes are organized within different parts of your application.

```
rosemary route:list --group
```

## List routes of a specific module

It may be useful to see the routes associated with a specific module. To do this, simply provide the module 
name as an argument:

```
rosemary route:list <module_name>
```

Replace `<module_name>` with the actual name of the module for which you want to see the routes.
