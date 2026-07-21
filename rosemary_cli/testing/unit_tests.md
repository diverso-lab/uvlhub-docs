---
layout: default
parent: Testing
grand_parent: Rosemary CLI
title: Running tests
permalink: /rosemary/testing/running_tests
nav_order: 1
---

# Running tests
{: .no_toc }

`rosemary test` runs the suite at the granularity of the [testing
pyramid]({{site.baseurl}}/rosemary/testing). You choose which levels run with flags; the command
translates them into a `pytest -m` expression and points pytest at the right part of
`app/features/`.

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

## Running everything by default

```
rosemary test
```

With no arguments this runs the four infrastructure-light levels — `unit`, `repository`, `service`
and `integration` — across every feature in `app/features/`. Browser and load tests are left out,
because they need a Selenium Grid and a Locust run respectively.

The command echoes what it is about to do, so you can always see the resolved selection:

```
Running unit or repository or service or integration tests against /workspace/app/features...
```

The target carries the `$WORKING_DIR` prefix inside a container. Outside Docker the same line reads
`against app/features...`.

## Running one feature

Pass a feature name to narrow the target to `app/features/<feature>/`:

```
rosemary test auth
```

The name must be a directory under `app/features/`. If it is not, the command stops with:

```
Feature 'auht' does not exist.
```

## Choosing levels

Six flags map onto the six markers. Each one turns its level on:

| Flag | Marker | Runs |
|---|---|---|
| `--unit` | `unit` | Pure logic, no app and no database |
| `--repository` | `repository` | Repositories against the database |
| `--service` | `service` | Services against the database |
| `--integration` | `integration` | HTTP tests via the Flask test client |
| `--e2e` | `e2e` | Selenium end-to-end tests, grid required |
| `--all` | all of the above | `unit`, `repository`, `service`, `integration` and `e2e` |

So a single level:

```
rosemary test auth --unit
```

Flags OR together, so combining them widens the selection rather than narrowing it:

```
rosemary test auth --unit --repository
```

That runs `pytest -m "unit or repository"`. It does not run tests that are somehow both — no test
carries two markers, since `pytestmark` is set once per module.

`--all` is a shortcut for the five pytest levels:

```
rosemary test --all
```

Note that `--all` includes `--e2e`. The Selenium Grid has to be up or those tests will fail. See
[GUI tests]({{site.baseurl}}/rosemary/testing/gui_tests).

## Filtering by expression

`-k` is passed straight through to pytest, so it takes the usual substring expression:

```
rosemary test -k password
```

It composes with everything else. Narrow to a feature, a level, and a name at once:

```
rosemary test auth --unit -k password
```

## The --load flag

`--load` does not run anything. Load tests are Locust scenarios, not pytest modules, so the flag
exists only to send you to the right command:

```
$ rosemary test --load
Use ``rosemary locust`` (optionally with a feature name) for load tests.
```

See [Load tests]({{site.baseurl}}/rosemary/testing/load_tests).

## What the command actually runs

`rosemary test` is a thin wrapper. It builds and executes:

```
pytest -v <target> -m "<markers joined by or>" [-k <expression>]
```

where `<target>` is `app/features` or `app/features/<feature>`, prefixed with `$WORKING_DIR` when
you are inside a container. Because the target is passed explicitly, it overrides `testpaths` from
the root `pyproject.toml` for that run.

If you ever need the raw invocation — to add a pytest flag rosemary does not expose, for instance —
you can run pytest directly:

```
pytest -v app/features/auth -m "unit or service" -k password
```

Do not add `--noconftest`. The root `conftest.py` sets `SPLENT_APP` and supplies the shared
fixtures, so disabling it breaks everything above the unit level.
