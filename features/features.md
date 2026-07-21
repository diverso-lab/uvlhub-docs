---
layout: default
title: Features
has_children: true
permalink: /features
nav_order: 5
---

# Features
{: .no_toc }

uvlhub is built as a set of features. Each one lives in its own package under `app/features/<name>/`
and owns everything it needs: blueprint, routes, models, repositories, services, templates, assets and
tests. There is no shared "modules" layer to coordinate with — a feature is self-contained.

{: .note }
> This directory used to be `app/modules/`. The domain word is now *feature*, not *module*. The Rosemary
> commands that operate on them were renamed too: `make:module` became `feature:create`, and
> `module:list` became `feature:list`.

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

## Which features are loaded

The set of features the app loads is declarative. It lives in the root `pyproject.toml` under
`[tool.splent]`:

```toml
[tool.splent]
features = [
    "auth",
    "dataset",
    "explore",
    "featuremodel",
    "flamapy",
    "hubfile",
    "profile",
    "public",
    "team",
    "zenodo",
]
features_dev = [
    "webhook",
]
features_prod = []
```

At startup, `app/feature_loader.py` reads these lists and loads the union of `features` and
`features_<env>`, where `env` is `prod` when the app is created with `config_name="production"` and
`dev` otherwise, which keeps `webhook` out of production.

The module-level `app = create_app(...)` that gunicorn imports passes `FLASK_ENV` as the config
name, so with `FLASK_ENV=production` the loader resolves the `prod` set and `webhook` is not
registered. See [Feature selection]({{site.baseurl}}/architecture/feature_selection) for the full
contract and the resolved per-environment table.

A package sitting in `app/features/` that is not named in either list is simply skipped. If neither
list is declared at all, every package found on disk is loaded.

{: .important-title }
> Where features are selected
>
> The `[tool.splent]` lists above are the only place features are selected. The canonical reference is
> [Feature selection]({{site.baseurl}}/architecture/feature_selection).

The `[tool.splent]` lists are the declarative source. To see what the running app actually registered,
list its routes:

```
rosemary route:list
```

That prints every registered blueprint endpoint with its methods and URL rule, grouped by endpoint
prefix, so a feature that failed to load shows up as a missing block of routes.

Ask Rosemary directly which features load:

```
rosemary feature:list
```

It resolves them through `app/feature_loader.py`, the same code the application runs at startup, so
the answer cannot drift from what actually loads. Pass `--env prod` to see the production set:

```
rosemary feature:list --env prod
```

The two lists differ by `webhook`, which is declared under `features_dev`. The command also flags
features declared in `pyproject.toml` but missing from disk, and features sitting in
`app/features/` that no list declares, so neither mistake stays invisible.

## The features

### Core features

| Feature | What it does |
|:--------|:-------------|
| `auth` | Signup, login and logout. Owns the `User` model and the login manager wiring. |
| `dataset` | Dataset upload, listing, download and DOI resolution (`/doi/<doi>/`). Also defines the REST resources at `/api/v1/datasets/` in `api.py`. |
| `explore` | Dataset search at `/explore`, filtering by query, sorting, publication type and tags. |
| `featuremodel` | The `FeatureModel`, `FMMetaData` and `FMMetrics` models, linking a dataset to its UVL files. |
| `flamapy` | UVL validation and format conversion through {% include flamapy.html %}: `check_uvl`, `valid`, `to_glencoe`, `to_splot`, `to_cnf`. |
| `hubfile` | Individual file download and view, at `/file/download/<id>` and `/file/view/<id>`. |
| `profile` | Profile editing at `/profile/edit` and the signed-in user's own summary at `/profile/summary`. |
| `public` | The landing page at `/`. |
| `team` | The static team page at `/team`. |
| `zenodo` | Deposition, upload and publication against the Zenodo REST API. See [Zenodo]({{site.baseurl}}/features/zenodo). |

### Development-only features

| Feature | What it does |
|:--------|:-------------|
| `webhook` | Receives a deploy POST at `/webhook/deploy`. Listed in `features_dev`, so it is not registered in production. |

## What a feature looks like

Not every feature has every file — a feature only carries what it needs. `public` and `team` are just a
blueprint plus templates, while `dataset` has the full set:

```
app/features/dataset/
├── __init__.py          # the blueprint
├── api.py
├── assets/
├── forms.py
├── models.py
├── repositories.py
├── routes.py
├── seeders.py
├── services.py
├── templates/
├── tests/
└── uvl_examples/
```

The loader imports `routes`, `models`, `hooks` and `signals` if they exist, then registers every Flask
`Blueprint` it finds in the feature root or those submodules. Two optional hooks are also honoured:
`config.inject_config(app)` runs before anything else touches `app.config`, and `init_feature(app)` in
the feature's `__init__.py` runs once the module is imported.

Base classes come from the `splent_framework` package, not from the repository:

```python
from splent_framework.blueprints.base_blueprint import BaseBlueprint
from splent_framework.repositories.BaseRepository import BaseRepository
from splent_framework.services.BaseService import BaseService
```

See [splent_framework]({{site.baseurl}}/architecture/splent_framework) for the full surface.

## Tests

Tests live inside the feature, in `app/features/<feature>/tests/`, one file per layer of the testing
pyramid:

```
app/features/zenodo/tests/
├── test_unit.py
├── test_repository.py
├── test_service.py
├── test_integration.py
└── test_selenium.py
```

Each file sets its marker at module level, for example `pytestmark = pytest.mark.service`. The markers
`unit`, `repository`, `service`, `integration`, `e2e` and `load` are declared in the root
`pyproject.toml`. Features that carry load tests add a `locustfile.py` alongside the others.

See [Testing]({{site.baseurl}}/rosemary/testing) for how to run each layer.

## Per-feature environment

A feature can ship its own `.env.example`. Today `zenodo` is the only one that does, because it is the
only feature needing a secret of its own:

```
app/features/zenodo/.env.example
```

You copy it to `.env` next to it, fill it in, and then merge every feature `.env` into the root one:

```
rosemary compose:env
```

That command walks `app/features/`, collects each `.env` it finds, and merges the variables into the
root `.env`, warning you about conflicts instead of overwriting. See
[Composing environment]({{site.baseurl}}/rosemary/extending_uvlhub/composing_environment).

## Creating a new feature

```
rosemary feature:create <name>
```

This scaffolds `app/features/<name>/` with a blueprint, routes, models, repositories, services, forms,
seeders, an index template, an asset script, and one test file per layer including a `locustfile.py`.

{: .warning }
The command does not touch `pyproject.toml`. Add the name to `[tool.splent] features` yourself,
otherwise the loader will skip the new feature and none of its routes will exist.

See [Create feature]({{site.baseurl}}/rosemary/extending_uvlhub/create_feature).
