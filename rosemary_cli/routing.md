---
layout: default
parent: Rosemary CLI
title: Routing
permalink: /rosemary/routing
nav_order: 5
---

# Routing
{: .no_toc }

The rosemary command `route:list` allows you to list all the routes available in the project. This command is useful for getting a quick overview of available endpoints and their corresponding HTTP methods.

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

## List all routes

To list the routes of every feature, run:

```
rosemary route:list
```

The output has three columns: the endpoint, the HTTP methods (with `HEAD` and `OPTIONS` filtered out) and the URL
rule.

## Group routes by feature

To get a grouped view, use the `--group` option. It splits the endpoints on the dot and groups them by the blueprint
name, which for a conventional feature is the feature name:

```
rosemary route:list --group
```

## List routes of a specific feature

It may be useful to see the routes associated with a single feature. To do this, provide the feature name as an
argument:

```
rosemary route:list <feature_name>
```

Replace `<feature_name>` with the name of the directory under `app/features/` whose routes you want to see, for
example:

```
rosemary route:list dataset
```

The command checks that `app/features/<feature_name>` exists before filtering, and then keeps only the endpoints
that start with `<feature_name>.`.

{: .note-title }
> The output still says "Module"
>
> `route:list` predates the rename from modules to features, and its grouped output still labels each group as
> `Module: <name>`. It is reading `app/features/` all the same.
