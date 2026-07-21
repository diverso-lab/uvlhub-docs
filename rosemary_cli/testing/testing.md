---
layout: default
parent: Rosemary CLI
title: Testing
has_children: true
permalink: /rosemary/testing
nav_order: 4
---

# Testing
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

## The testing pyramid

{% include uvlhub.html %} organises its tests into six levels. Each level is a `pytest` marker, and
every marker is declared in the root `pyproject.toml`:

```toml
[tool.pytest.ini_options]
markers = [
    "unit: pure unit tests, no Flask app, no database",
    "repository: repository tests against the database (no business logic)",
    "service: service-level tests against the database (orchestration + repos)",
    "integration: HTTP-level integration tests via Flask test client",
    "e2e: browser-driven end-to-end tests (requires the selenium grid)",
    "load: locust load tests (run via `rosemary locust`)",
]
```

What belongs at each level:

| Marker | Level | What belongs there |
|---|---|---|
| `unit` | Unit | Pure logic. No Flask app, no database. Model methods, helpers, validators. |
| `repository` | Repository | A repository exercised against a real database. Queries and persistence only, no business rules. |
| `service` | Service | A service against a real database. Orchestration across repositories, with external HTTP mocked. |
| `integration` | Integration | The HTTP surface, driven through the Flask test client. Status codes, redirects, rendered pages. |
| `e2e` | End to end | A real browser driving the running application through the Selenium Grid. |
| `load` | Load | Locust scenarios that put concurrent traffic on the application. |

The first four levels need no external infrastructure beyond the database, so they are the ones that
run by default and the ones that run in CI. The last two need a Selenium Grid and a Locust run
respectively, so you opt into them explicitly.

## Where tests live

Tests live next to the feature they exercise, inside `app/features/<feature>/tests/`. There is one
file per level:

```
app/features/auth/tests/
├── __init__.py
├── locustfile.py          # load
├── test_integration.py    # integration
├── test_repository.py     # repository
├── test_selenium.py       # e2e
├── test_service.py        # service
└── test_unit.py           # unit
```

A feature only ships the files that make sense for it. Not every feature has all six.

`testpaths` in the root `pyproject.toml` points at both the feature tree and the top-level `tests/`
directory, so a bare `pytest` collects everything:

```toml
testpaths = ["app/features", "tests"]
python_files = ["test_*.py"]
```

The top-level `tests/` package holds cross-feature support code rather than tests of its own. Today
that is `tests/selenium_support.py`, the driver and host resolution used by the e2e layer.

## The pytestmark convention

Every test module declares its level once, at module level, with `pytestmark`. You do not decorate
individual test functions:

```python
"""Unit tests for the auth feature — pure logic, no Flask app, no DB."""

import pytest

from app.features.auth.models import User

pytestmark = pytest.mark.unit


def test_set_password_hashes_value():
    user = User(email="alice@example.com")
    user.set_password("secret")
    assert user.password != "secret"
    assert user.check_password("secret") is True
```

This is what makes marker selection work. When you run `rosemary test auth --unit`, pytest is
invoked with `-m unit`, and only the modules carrying that `pytestmark` are collected.

The `load` marker is the exception. Locust scenarios are not pytest modules, so `locustfile.py`
carries no `pytestmark` and is never collected by pytest. The marker is declared for completeness;
load tests are driven by `rosemary locust`.

## Shared fixtures

The root `conftest.py` sets `SPLENT_APP=app` so the framework's app loader can resolve
`create_app("testing")`, and re-exports the fixtures shipped by `splent_framework` so that every
collected test picks them up:

```python
import os

os.environ.setdefault("SPLENT_APP", "app")

from splent_framework.fixtures.fixtures import (  # noqa: E402, F401
    clean_database,
    test_app,
    test_client,
    test_client_module,
)
```

Because this file provides both the environment and the fixtures, do not run pytest with
`--noconftest`. Tests that need a `test_client` or a clean database will fail without it.

Fixtures that only make sense for one feature belong in
`app/features/<feature>/tests/conftest.py`. Each fixture, its scope, and how often it resets the
database is covered in [Test fixtures]({{site.baseurl}}/rosemary/testing/fixtures).

## Running the levels

Each level has its own page:

- [Running tests]({{site.baseurl}}/rosemary/testing/running_tests) — `rosemary test` and its marker flags.
- [Test coverage]({{site.baseurl}}/rosemary/testing/test_coverage) — `rosemary coverage`, same flags plus a report.
- [Load tests]({{site.baseurl}}/rosemary/testing/load_tests) — `rosemary locust` and the Locust web UI.
- [GUI tests]({{site.baseurl}}/rosemary/testing/gui_tests) — `rosemary selenium`, the grid, and watching a run over VNC.
- [Test fixtures]({{site.baseurl}}/rosemary/testing/fixtures) — `test_app`, `test_client`, and why the database is empty.

The short version:

```
rosemary test                  # unit + repository + service + integration, all features
rosemary test auth             # the same four levels, auth only
rosemary test auth --e2e       # browser tests for auth (grid must be up)
rosemary coverage --html       # default levels with an HTML coverage report
rosemary locust auth           # load test the auth feature
```

## What CI runs

`.github/workflows/CI_pytest.yml` (workflow name `Pytest`) runs on every push and pull request
against `main`. It brings up a MariaDB service container, installs the project with Python 3.13, and
runs:

```
pytest app/features/ --ignore-glob='*selenium*'
```

No `-m` flag is passed, so every collected marker runs. The browser tests are excluded by path, not
by marker, because CI has no Selenium Grid. Load tests are never collected by pytest at all.
