---
layout: default
parent: Testing
grand_parent: Rosemary CLI
title: Test fixtures
permalink: /rosemary/testing/fixtures
nav_order: 5
---

# Test fixtures
{: .no_toc }

Every test above the `unit` level needs a Flask application, a database, or both. {% include uvlhub.html %}
does not define those fixtures itself: they ship with `splent_framework` and the root `conftest.py`
re-exports them so that every collected test can use them by name.

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

## Where the fixtures come from

The whole wiring is the repo-root `conftest.py`:

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

Two things happen there, in that order, and the order matters.

`SPLENT_APP=app` is set **before** the fixtures are imported. The framework's app loader reads that
variable to know which package to import, then calls `create_app("testing")` on it. Setting it in
`conftest.py` rather than in your shell is what lets a bare `pytest` work on a fresh clone.

The four fixtures are then re-exported at the root of the project, so pytest hands them to any test
in `app/features/**` or `tests/` that asks for them by parameter name. You never import them
yourself.

{: .warning-title }
> <i class="fa-solid fa-triangle-exclamation"></i> Do not run pytest with --noconftest
>
> That flag disables the file above, which takes `SPLENT_APP` and all four fixtures with it.
> Everything except the `unit` level will fail to even set up.

## What "testing" mode changes

`create_app("testing")` loads `TestingConfig`, which differs from the development configuration in
three ways that you will notice while writing tests:

| Setting | Value under `testing` | Consequence |
|---|---|---|
| `SQLALCHEMY_DATABASE_URI` | built from `MARIADB_TEST_DATABASE` | Tests use a separate database, `uvlhubdb_test` by default. Your seeded development data is never touched. |
| `TESTING` | `True` | Flask propagates exceptions instead of rendering the 500 page. |
| `WTF_CSRF_ENABLED` | `False` | Form POSTs need no CSRF token. |

That last one is why integration tests can post a plain `data={...}` dictionary straight at a route,
with no token round-trip:

```python
test_client.post(
    "/login",
    data={"email": "nobody@example.com", "password": "wrong"},
    follow_redirects=False,
)
```

## The reset

All four fixtures are built on the same private helper in
`splent_framework.fixtures.fixtures`:

```python
def _reset_db():
    """Drop and recreate all tables. Disables FK checks for MariaDB."""
    db.session.remove()
    with db.engine.connect() as conn:
        conn.execute(text("SET FOREIGN_KEY_CHECKS=0"))
        db.metadata.drop_all(bind=conn)
        conn.execute(text("SET FOREIGN_KEY_CHECKS=1"))
        db.metadata.create_all(bind=conn)
        conn.commit()
```

It drops every table SQLAlchemy knows about and creates them again, empty. Foreign key checks are
switched off around the drop because MariaDB will otherwise refuse to drop tables that are still
referenced. What differs between the fixtures is only *how often* this runs.

## The four fixtures

| Fixture | Scope | Resets the database | App context active in your test |
|---|---|---|---|
| `test_app` | session | Once, when the session starts | No |
| `test_client` | function | Before **every** test | No |
| `test_client_module` | module | Once, when the module starts | Yes |
| `clean_database` | function | Before every test that requests it | Yes |

### test_app

Session-scoped. It builds the application once for the whole pytest run and resets the tables once,
at that moment. Every other fixture depends on it, so the application is only ever created once no
matter how many tests you run.

It yields the app object with no application context pushed, so a test that touches the database
directly has to push one:

```python
"""Repository-level tests for auth — UserRepository against the DB."""

import pytest

from app.features.auth.repositories import UserRepository

pytestmark = pytest.mark.repository


def test_create_then_get_by_email(test_app):
    with test_app.app_context():
        repo = UserRepository()
        repo.create(email="dave@example.com", password="davepass")
        found = repo.get_by_email("dave@example.com")
        assert found is not None
        assert found.check_password("davepass") is True
```

Because the reset happens once per session, `test_app` on its own gives you whatever rows earlier
tests left behind. If your test needs a guaranteed empty database, ask for `clean_database` as well.

### test_client

Function-scoped, and the one you will use most. It **drops and recreates all tables before every
single test**, then yields a Flask test client:

```python
@pytest.fixture(scope="function")
def test_client(test_app):
    with test_app.app_context():
        _reset_db()
    with test_app.test_client() as client:
        yield client
```

Tests are therefore fully isolated from each other and order-independent. The cost is one full
drop-and-create per test, which is why the suite is not instantaneous.

Note that the reset happens inside an application context that is then exited. The client is yielded
with no context pushed, so if a test wants to query the database directly alongside its HTTP calls,
it takes `test_app` too and opens a context explicitly.

### test_client_module

Module-scoped. It resets the database once when the module starts and then shares that client, and
that state, across every test in the file. Unlike `test_client`, it keeps the application context
pushed for the whole module.

Use it when a file describes one long scenario whose steps build on each other. The trade-off is
that the tests become order-dependent: run one on its own with `-k` and it may fail because the
earlier steps never happened. No feature in the repository uses it today; every module either takes
`test_client` per test or pairs `test_app` with `clean_database`.

### clean_database

Function-scoped, and it yields nothing useful. Its only job is to force a reset for the test that
asks for it, and to leave an application context pushed while that test runs.

Pair it with `test_app` when you want the isolation of `test_client` without going through HTTP.
This is the standard shape for `repository` and `service` tests that need to start from empty:

```python
"""Service-level tests for public — the statistics the landing page aggregates."""

import pytest

from app.features.dataset.services import DataSetService
from app.features.featuremodel.services import FeatureModelService

pytestmark = pytest.mark.service


def test_homepage_statistics_are_zero_on_empty_database(test_app, clean_database):
    with test_app.app_context():
        dataset_service = DataSetService()
        feature_model_service = FeatureModelService()

        assert dataset_service.latest_synchronized() == []
        assert dataset_service.count_synchronized_datasets() == 0
        assert feature_model_service.count_feature_models() == 0
```

It also composes with `test_client_module`, where it gives you a selective reset in the middle of an
otherwise shared module.

---

## The database is empty

This is the thing that catches people out, so it is worth stating on its own:

{: .warning-title }
> <i class="fa-solid fa-triangle-exclamation"></i> There is no seed data in tests
>
> A test using `test_client` starts against a database with the correct schema and **zero rows**.
> The seeders are not run. There is no default user, no default dataset, nothing. Every test creates
> the rows it needs.

The [`rosemary db:seed`]({{site.baseurl}}/rosemary/managing_database/seeders) data lives in the
development database. Tests point at `MARIADB_TEST_DATABASE`, which is a different database
entirely, and every fixture drops and recreates its tables before handing it to you. Nothing
survives.

In practice this means a test that needs a logged-in user signs one up first. From
`app/features/profile/tests/test_integration.py`:

```python
"""HTTP integration tests for profile via the Flask test client."""

import pytest

pytestmark = pytest.mark.integration


def signup(test_client, email="profile-user@example.com", name="Ada", surname="Lovelace"):
    """Register and log in a user, returning the response of the signup POST."""
    return test_client.post(
        "/signup/",
        data={"email": email, "password": "profilepass", "name": name, "surname": surname},
        follow_redirects=False,
    )


def test_summary_renders_profile_details(test_app, test_client):
    signup(test_client, email="summary@example.com", name="Ada", surname="Lovelace")

    response = test_client.get("/profile/summary")

    assert response.status_code == 200
    body = response.get_data(as_text=True)
    assert "Ada" in body
    assert "summary@example.com" in body
    assert "0 datasets" in body
```

The `signup` helper is not a fixture, just a module-level function. It posts to a real route, which
both creates the user and logs the client in, and it works without a CSRF token because
`WTF_CSRF_ENABLED` is `False`. The assertion `"0 datasets" in body` is only reliable *because* the
database started empty.

Repository and service tests do the same thing at a lower level, with small module-level factory
functions that build the rows straight through the repositories or the session. Look at
`app/features/dataset/tests/test_service.py` and `app/features/explore/tests/test_repository.py`
for worked examples.

The one exception to all of this is the `e2e` level. Selenium tests drive a real browser against the
running application, so they see the **seeded development database** and none of these fixtures
apply. See [GUI tests]({{site.baseurl}}/rosemary/testing/gui_tests).

## Per-feature fixtures

The root `conftest.py` is deliberately minimal: environment plus the four shared fixtures, nothing
else. Anything that only makes sense for one feature belongs next to that feature's tests:

```
app/features/<feature>/tests/conftest.py
```

pytest merges conftest files down the directory tree, so a fixture defined there is visible to every
test module in that feature and invisible everywhere else. That is where an authenticated client, a
prebuilt dataset, or a mocked external service for one feature should live.

Do not add feature-specific fixtures to the root `conftest.py`. Every test in the project pays the
import cost, and names collide quickly once several features want their own `logged_in_client`.

## Choosing a fixture

Start from what the test needs:

- Pure logic, no app, no database. Take no fixture at all. This is the `unit` level.
- HTTP surface, fresh database per test. Take `test_client`.
- HTTP surface plus direct database assertions. Take `test_app, test_client` and open a context for
  the assertions.
- Repositories or services, fresh database per test. Take `test_app, clean_database`.
- Repositories or services where leftover state is genuinely irrelevant. Take `test_app` alone.
- One long scenario spread across a file. Take `test_client_module`, and accept the order
  dependency.
