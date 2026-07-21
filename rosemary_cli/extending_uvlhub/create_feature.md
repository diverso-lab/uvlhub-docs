---
layout: default
parent: Extending uvlhub
grand_parent: Rosemary CLI
title: Create feature
permalink: /rosemary/extending_uvlhub/create_feature
nav_order: 1
---

# Create feature
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

## About

The unit of extension in {% include uvlhub.html %} is a **feature**. A feature is a self-contained
package under `app/features/` that owns its blueprint, model, repository, service, form, seeder,
templates, assets and tests.

`rosemary feature:create` scaffolds a complete feature, including the six test files of the testing
pyramid, each one already tagged with the right pytest marker. You get a runnable feature from the
first second, not an empty folder.

## Create a feature

Run the command from inside the application container:

```
docker exec -it web_app_container rosemary feature:create <feature_name>
```

Or, if you already have a shell inside the container:

```
rosemary feature:create <feature_name>
```

Replace `<feature_name>` with the name of your feature. Use `snake_case`: the generator derives the
class prefix by PascalCasing the name, so `feature_model` becomes `FeatureModel`.

On success you will see:

```
Feature 'notepad' created successfully.
Feature 'notepad' permissions changed successfully.
```

The second line is not decoration. The generator chowns everything it wrote to UID/GID `1000` so the
files created from inside the container belong to you on the host.

{: .note-title }
> Note
>
> If a feature named `<feature_name>` already exists, `rosemary` tells you so and writes nothing.
> No existing file is ever overwritten.

## What gets generated

For `rosemary feature:create notepad`, the generator produces exactly this tree:

```
app/features/notepad/
├── __init__.py
├── forms.py
├── models.py
├── repositories.py
├── routes.py
├── seeders.py
├── services.py
├── assets/
│   └── js/
│       └── scripts.js
├── templates/
│   └── notepad/
│       └── index.html
└── tests/
    ├── __init__.py
    ├── locustfile.py
    ├── test_unit.py
    ├── test_repository.py
    ├── test_service.py
    ├── test_integration.py
    └── test_selenium.py
```

### The feature package

`__init__.py` declares the blueprint and the feature's `init_feature` hook. `BaseBlueprint` comes
from `splent_framework` and adds the asset route on top of a plain Flask `Blueprint`:

```python
from flask import Flask
from splent_framework.assets.asset_registry import register_asset
from splent_framework.blueprints.base_blueprint import BaseBlueprint

notepad_bp = BaseBlueprint('notepad', __name__, template_folder='templates')


def init_feature(app: Flask) -> None:
    """Declare this feature's javascript with the framework asset registry.

    The shell renders every declared asset from one place, so do not add a
    <script> tag to this feature's template. One consequence: the script is
    then served on every page, so guard any DOM wiring with a check for an
    element that only exists on this feature's page.

    To add an entry to the main navigation, also call:

        from splent_framework.nav.nav_registry import register_nav_item
        register_nav_item("notepad", "notepad", "/notepad", order=100, icon="box")
    """
    register_asset("js", "notepad.assets", subfolder="js", filename="scripts.js")
```

`init_feature` is the lifecycle hook the loader calls once the feature's modules are imported. It is
where a feature contributes to the shell: its script here, and its navigation entry if it has one.
The generated docstring already carries the sidebar recipe; `public`, `explore` and `team` are the
shipped features that use it, along the lines of:

```python
from splent_framework.nav.nav_registry import register_nav_item

register_nav_item("notepad", "Notepad", "/notepad", order=100, icon="book")
```

`routes.py` has one route already wired to the template:

```python
from flask import render_template
from app.features.notepad import notepad_bp


@notepad_bp.route('/notepad', methods=['GET'])
def index():
    return render_template('notepad/index.html')
```

`models.py`, `repositories.py` and `services.py` give you the three layers, with the base classes
imported from `splent_framework`:

```python
# models.py
from app import db


class Notepad(db.Model):
    id = db.Column(db.Integer, primary_key=True)

    def __repr__(self):
        return f'Notepad<{self.id}>'
```

```python
# repositories.py
from app.features.notepad.models import Notepad
from splent_framework.repositories.BaseRepository import BaseRepository


class NotepadRepository(BaseRepository):
    def __init__(self):
        super().__init__(Notepad)
```

```python
# services.py
from app.features.notepad.repositories import NotepadRepository
from splent_framework.services.BaseService import BaseService


class NotepadService(BaseService):
    def __init__(self):
        super().__init__(NotepadRepository())
```

`forms.py` is a Flask-WTF form with nothing but a submit button, ready for you to add fields.

`seeders.py` gives you a seeder picked up automatically by `rosemary db:seed`:

```python
from splent_framework.seeders.BaseSeeder import BaseSeeder


class NotepadSeeder(BaseSeeder):

    def run(self):

        data = [
            # Create any Model object you want to make seed
        ]

        self.seed(data)
```

`db:seed` runs seeders in ascending order of a `priority` class attribute, defaulting to `0`. If your
feature depends on rows created by another one, declare a higher number, the way
`app/features/dataset/seeders.py` declares `priority = 2` so it runs after
`app/features/auth/seeders.py`, which declares `priority = 1` and creates the users it needs.

### Test files

This is the part that makes `feature:create` worth using. Every layer of the testing pyramid gets its
own file. The five `test_*.py` files each set `pytestmark` at module level so `rosemary test` can
select them; `locustfile.py` is not a pytest module and is driven by `rosemary locust` instead.

| File | Marker | What belongs there |
|:---|:---|:---|
| `tests/test_unit.py` | `pytest.mark.unit` | Pure logic. No Flask app, no database. |
| `tests/test_repository.py` | `pytest.mark.repository` | The repository against a real database, no service orchestration. |
| `tests/test_service.py` | `pytest.mark.service` | Services plus repositories against a real database, no HTTP. |
| `tests/test_integration.py` | `pytest.mark.integration` | HTTP through the Flask test client. |
| `tests/test_selenium.py` | `pytest.mark.e2e` | Browser-driven, against the Selenium grid. |
| `tests/locustfile.py` | n/a (not collected by pytest) | Load testing, run with `rosemary locust`. |

The markers themselves are declared in the root `pyproject.toml`, under
`[tool.pytest.ini_options]`. That same section sets `python_files = ["test_*.py"]`, which is why
`locustfile.py` never reaches pytest and carries no marker of its own.

The integration stub is already a real assertion, not a placeholder:

```python
"""HTTP integration tests for the notepad feature.

Drive the application through the Flask test client. The ``test_client``
fixture from splent_framework rebuilds a clean DB per test for full isolation.
"""
import pytest

pytestmark = pytest.mark.integration


def test_notepad_index_responds(test_client):
    response = test_client.get("/notepad")
    assert response.status_code == 200, "/notepad did not return 200"
```

The `test_client` and `test_app` fixtures come from `splent_framework.fixtures.fixtures` and are
re-exported for the whole project by the root `conftest.py`, so you do not import them yourself.

Run the fast layers for your new feature with:

```
rosemary test notepad
```

That runs `unit`, `repository`, `service` and `integration`. Add `--e2e` for the browser tests, or
`--all` for everything except load.

{: .note-title }
> The Selenium stub knows it might not be loaded
>
> `tests/test_selenium.py` imports `close_driver`, `get_host_for_selenium_testing` and
> `initialize_driver` from the repo-local `tests/selenium_support`, a thin wrapper that fills in
> uvlhub's grid and target URLs under Docker and pins a 1920x1080 viewport on top of the
> `splent_framework` helpers. The stub opens `/notepad` through the grid and asserts the answer is
> not the 404 page, because scaffolding a feature does not load it: until you declare the feature,
> the test fails with the fix spelled out in its message — add `notepad` to `[tool.splent]` in the
> root `pyproject.toml` and restart the app. Its docstring also carries the run instructions and a
> warning that e2e tests hit the live seeded database, so keep them read-only or clean up after
> yourself. See `app/features/team/tests/test_selenium.py` for a fleshed-out example.

### Templates and assets

The generated `templates/notepad/index.html` extends the global base template:

```jinja
{% raw %}{% extends "base_template.html" %}

{% block title %}View notepad{% endblock %}

{% block content %}

{% endblock %}

{# This feature's script is declared with register_asset in __init__.py and
   rendered by base_template.html, so there is no script tag here. #}{% endraw %}
```

There is deliberately no `<script>` tag. `BaseBlueprint` registers an `assets` endpoint serving
`/<feature>/<subfolder>/<filename>`, and the script is declared once with `register_asset` in
`init_feature`. `base_template.html` renders every declared asset from a single place, deduplicated
and ordered.

{: .warning-title }
> A registered script loads on every page
>
> The asset registry is global: once declared, your `scripts.js` is served on every page of the
> application, not only on your feature's. Anything that touches the DOM has to check first that it
> is on the right page, or it will throw everywhere else:
>
> ```javascript
> document.addEventListener('DOMContentLoaded', () => {
>     if (!document.getElementById('notepad-list')) return;
>     // safe to wire the notepad page from here
> });
> ```
>
> `explore` and `dataset` in this repository are worked examples of that guard.

## Register the feature

Scaffolding a feature is not enough to load it. Feature selection is declarative: `app/feature_loader.py`
reads the lists under `[tool.splent]` in the **root** `pyproject.toml` and skips any package under
`app/features/` that is not declared there.

```toml
[tool.splent]
features = [
    "auth",
    "dataset",
    "explore",
    "featuremodel",
    "flamapy",
    "hubfile",
    "notepad",
    "profile",
    "public",
    "team",
    "zenodo",
]
features_dev = [
    "webhook",
]
features_prod = [
    "webhook",
]
```

`features` is the base list. `features_dev` adds entries when the app runs in development or testing,
`features_prod` when it runs in production. The loaded set is the union of `features` and the list for
the current environment.

{: .important-title }
> Reboot required!
>
> Flask registers blueprints at startup, so a newly created feature is invisible until the container
> restarts:
>
> ```
> docker restart web_app_container
> ```

Once it is back up, confirm the routes were registered:

```
docker exec -it web_app_container rosemary route:list notepad
```

You should see something like this:

```
No product config.py found for 'splent_app', using SPLENT default config.
Listing routes for the 'notepad' module...
Endpoint          Methods    Route
------------------------------------------------------------
notepad.assets    GET        /notepad/<subfolder>/<filename>
notepad.index     GET        /notepad
```

Every `rosemary` invocation prints the `No product config.py found for 'splent_app', using SPLENT
default config.` banner first. It is harmless, not an error.

## Listing features

`rosemary feature:list` prints the features this product loads:

```
rosemary feature:list
```

It resolves them through `app/feature_loader.py`, the same code path the application uses at startup,
so the listing cannot drift from what actually loads. Add `--env` to resolve a different environment's
list:

```
rosemary feature:list --env prod
```

Beyond the loaded set, it reports two mistakes that are otherwise easy to miss: a feature declared in
`[tool.splent]` with no directory under `app/features/`, and a feature directory that no list
declares, which therefore never loads.

To see the result from the other end, the routes the running app actually registered:

```
docker exec -it web_app_container rosemary route:list --group
```

The grouped output prints one section per registered blueprint, so a feature that is on disk but
missing from `[tool.splent]` simply will not appear.
