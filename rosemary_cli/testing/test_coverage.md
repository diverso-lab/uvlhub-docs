---
layout: default
parent: Testing
grand_parent: Rosemary CLI
title: Test coverage
permalink: /rosemary/testing/test_coverage
nav_order: 2
---

# Test coverage
{: .no_toc }

`rosemary coverage` runs the suite under `pytest-cov`. It takes the same feature argument, the same
`-k` filter and the same marker flags as [`rosemary test`]({{site.baseurl}}/rosemary/testing/running_tests),
so the coverage figure always reflects exactly the levels you asked for.

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

## Coverage of every feature

```
rosemary coverage
```

This measures `app/features/` while running the four default levels: `unit`, `repository`,
`service` and `integration`. The report is printed to the terminal as `term-missing`, which lists
each file with its uncovered line numbers.

{: .warning-title }
> <i class="fa-solid fa-triangle-exclamation"></i> No HTML by default
>
> The bare command writes a terminal report only. If you expect to find an `htmlcov/` directory
> afterwards, you need `--html`.

## Coverage of one feature

```
rosemary coverage auth
```

The target becomes `app/features/auth/`, and so does the `--cov` source, so the percentage is
scoped to that feature rather than diluted across the whole tree. The name must be a directory
under `app/features/`. If it is not, the command stops with the name you typed echoed back:

```
Feature 'auht' does not exist.
```

## Choosing levels

The marker flags match `rosemary test` one for one:

| Flag | Marker |
|---|---|
| `--unit` | `unit` |
| `--repository` | `repository` |
| `--service` | `service` |
| `--integration` | `integration` |
| `--e2e` | `e2e` |
| `--all` | `unit`, `repository`, `service`, `integration` and `e2e` |

As with `rosemary test`, flags OR together, and omitting all of them gives you
`unit or repository or service or integration`.

Coverage from the unit layer alone, which is the fastest signal:

```
rosemary coverage auth --unit
```

Coverage from the two database-backed layers:

```
rosemary coverage auth --repository --service
```

Coverage across everything pytest can drive, browser tests included. The Selenium Grid must be up
for this to mean anything:

```
rosemary coverage --all
```

## Filtering by expression

`-k` is forwarded to pytest exactly as it is for `rosemary test`:

```
rosemary coverage auth --unit -k password
```

## Command options

### `--html`

Adds an HTML report on top of the terminal one. It is written to `htmlcov/` in the directory you ran
the command from, so run it from the project root to get `htmlcov/` there:

```
rosemary coverage --html
```

Open `htmlcov/index.html` in a browser to click through the annotated sources.

`--html` combines with everything else:

```
rosemary coverage auth --repository --service --html
```

## What the command actually runs

```
pytest <target> --cov=<target> --cov-report=term-missing -m "<markers>" [--cov-report=html] [-k <expression>]
```

`<target>` is `app/features` or `app/features/<feature>`, prefixed with `$WORKING_DIR` inside a
container. The equivalent raw invocation is:

```
pytest app/features/auth --cov=app/features/auth --cov-report=term-missing -m "unit or service"
```
