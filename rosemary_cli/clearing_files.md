---
layout: default
parent: Rosemary CLI
title: Clearing files
permalink: /rosemary/clearing_files
nav_order: 8
---

# Clearing files
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

## Clear cache

```
rosemary clear:cache
```

This command is used to clear the pytest cache in the `app/modules` directory and the build directory in the root of the project. After confirming the action, the command removes the `.pytest_cache` folder, the `build` folder, all `__pycache__` directories and all `.pyc` files found in the project.


## Clear log

```
rosemary clear:log
```

This command is used to clear the `app.log` file.

## Clear uploads

```
rosemary clear:uploads
```

This command clears the `uploads` folder used by users to upload dataset files. 