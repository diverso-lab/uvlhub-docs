---
layout: default
parent: Rosemary CLI
title: Linting
permalink: /rosemary/linting
nav_order: 9
---

# Linting
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}


## Check Python syntax

```
rosemary linter
```

This command is designed to run the linter [Flake8](https://flake8.pycqa.org/en/latest/) in the `app`, `rosemary` and `core` directories to check the quality of the code.

## Auto-fix Python code style

```
rosemary linter:fix
```

This command automatically formats and cleans the code in the  `app`, `rosemary` and `core` directories, applying tools like Black and Autoflake to fix style issues detected by the linter.

## Using flake8 directly

You can run flake8 directly on the desired directories. To do this, run:

```
flake8 app rosemary core
```