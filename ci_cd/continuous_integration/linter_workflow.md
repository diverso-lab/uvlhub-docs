---
layout: default
grand_parent: CI/CD
parent: Continuous integration
title: Linter workflow
permalink: /ci_cd/continuous_integration/linter_workflow
nav_order: 2
---

# Linter workflow
{: .no_toc }

{: .important-title }
>
> Path to file [(view file on GitHub)](https://github.com/diverso-lab/uvlhub/blob/main/.github/workflows/CI_lint.yml)
> 
> The original file is located at the following path:
>
> ```
> .github / workflows / CI_lint.yml 
> ```

This GitHub Actions workflow enforces code style on every push and every pull request. It runs three independent checks: `flake8` for PEP 8 compliance, `black` for formatting and `isort` for import ordering. All three run against the same two directories, `app` and `rosemary`.

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

## Workflow name

- **name**: `Python Lint`

## Triggers

```yaml
on:
  push:
  pull_request:
```

Both triggers are bare, so the workflow runs on every branch and every pull request, not only on `main`. Style problems are caught on the branch, before review.

## Job

- **lint**: runs on `ubuntu-24.04`.

## Steps

### 1. Checkout

```yaml
- name: Checkout
  uses: actions/checkout@v5
```

### 2. Set up Python

```yaml
- name: Set up Python
  uses: actions/setup-python@v6
  with:
    python-version: '3.13'
```

### 3. Install dependencies

```yaml
- name: Install Dependencies
  run: |
    python -m pip install --upgrade pip
    pip install flake8 flake8-pyproject black isort
```

This job does not install `requirements.txt`. It only needs the style tools, so it installs them directly and stays fast.

`flake8-pyproject` is what lets `flake8` read its configuration from `pyproject.toml`. Without it, `flake8` ignores the `[tool.flake8]` table and falls back to its 79 character default, which reports several hundred spurious `E501` errors against a codebase formatted to 120 characters.

### 4. Lint with flake8

```yaml
- name: Lint with flake8
  run: flake8 app rosemary
```

### 5. Check formatting with black

```yaml
- name: Check formatting with black
  run: black --check app rosemary
```

`--check` makes `black` report and fail instead of rewriting files. The job never modifies your code.

### 6. Check import order with isort

```yaml
- name: Check import order with isort
  run: isort --check-only app rosemary
```

Same idea: `--check-only` reports and fails, it does not reorder anything.

## Configuration

There is no `.flake8` file and no `setup.cfg`. All three tools read the root `pyproject.toml`:

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

The settings are deliberately consistent. `isort` uses `profile = "black"` and the same line length, so `isort` and `black` cannot disagree with each other, and `flake8` ignores `E203` and `W503` because those two rules conflict with how `black` formats slices and line breaks around binary operators.

## Reproducing the checks locally

Run the same three commands from inside `web_app_container`, which already has `flake8`, `flake8-pyproject`, `black` and `isort` installed and starts at `/workspace`. Without `flake8-pyproject`, `flake8` will not pick up `[tool.flake8]` from `pyproject.toml`:

```bash
docker exec -it web_app_container flake8 app rosemary
docker exec -it web_app_container black --check app rosemary
docker exec -it web_app_container isort --check-only app rosemary
```

To fix the failures instead of just listing them, drop the check flags:

```bash
docker exec -it web_app_container isort app rosemary
docker exec -it web_app_container black app rosemary
```

`rosemary` also wraps this. `rosemary linter` runs `flake8` over both directories, and `rosemary linter:fix` removes unused imports with `autoflake`, sorts imports with `isort` and formats with `black`:

```bash
docker exec -it web_app_container rosemary linter
docker exec -it web_app_container rosemary linter:fix
```

See [Linting]({{site.baseurl}}/rosemary/linting) for more detail on the CLI commands.

{: .warning-title }
> `rosemary linter` is not the same as the CI job
>
> `rosemary linter` only runs `flake8`. The CI job also runs `black --check` and `isort --check-only`,
> so a branch that passes `rosemary linter` can still fail the workflow. Run `rosemary linter:fix` before
> pushing, or run the three commands above directly.
