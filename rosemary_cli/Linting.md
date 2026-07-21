---
layout: default
parent: Rosemary CLI
title: Linting
permalink: /rosemary/linting
nav_order: 8
---

# Linting
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

## Where the configuration lives

There is no `.flake8` file and no `setup.cfg`. Every tool reads the root `pyproject.toml`:

```toml
[tool.black]
line-length = 120
target-version = ["py313"]

[tool.isort]
line_length = 120
profile = "black"

[tool.flake8]
max-line-length = 120
extend-ignore = ["E203", "W503"]
```

flake8 has no native support for `pyproject.toml`. The [Flake8-pyproject](https://pypi.org/project/Flake8-pyproject/)
plugin, pinned in `requirements.txt`, is what teaches it to read the `[tool.flake8]` table. It is installed with the
rest of the dependencies, so you do not need to do anything extra.

## Check Python syntax

```
rosemary linter
```

This runs [Flake8](https://flake8.pycqa.org/en/latest/) over the `app` and `rosemary` directories, one at a time, and
reports whether each one is clean. Both target directories are resolved against `WORKING_DIR`, and the command passes
no `--config` flag: Flake8-pyproject discovers the `[tool.flake8]` table in `pyproject.toml` on its own, so
`rosemary linter` works from any directory.

If flake8 finds issues in either directory, `rosemary linter` reports them and exits with a non-zero status, so the
command can be used as a gate in a script or a pre-commit hook. When both directories are clean it exits 0.

## Auto-fix Python code style

```
rosemary linter:fix
```

This rewrites the files in `app` and `rosemary` in place, applying three tools in order:

1. `autoflake` removes unused imports and unused variables, recursively.
2. `isort` sorts the imports.
3. `black --line-length=120` formats the code.

Run it before committing. Most of what `rosemary linter` complains about is fixed by this command.

## Using flake8 directly

You can also call the tools yourself from the project root:

```
flake8 app rosemary
```

Thanks to Flake8-pyproject, this picks up `[tool.flake8]` from `pyproject.toml` without any extra flag.

The equivalent checks for the formatters, which report problems without modifying anything:

```
black --check app rosemary
isort --check-only app rosemary
```

## What CI runs

The `Python Lint` workflow (`.github/workflows/CI_lint.yml`) runs on every push and every pull request. It sets up
Python 3.13 and then executes exactly the three commands above:

```
flake8 app rosemary
black --check app rosemary
isort --check-only app rosemary
```

If those three pass locally, the lint job will pass too.
