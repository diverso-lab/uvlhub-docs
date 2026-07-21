---
layout: default
title: team
parent: Features
permalink: /features/team
nav_order: 9
---

# team
{: .no_toc }

The `team` feature serves the static page at `/team` that presents the institutions behind
{% include uvlhub.html %}: the University of Seville, the University of Malaga and the University of
Ulm, one card each, with a short description of what every partner contributes and a link to its
website. The page is public — no session is needed to see it.

Together with [webhook]({{site.baseurl}}/features/webhook), `team` is one of only two features in the
product that import nothing from any other feature and that no other feature imports. It is what a
maximally decoupled feature looks like here: remove `team` from `[tool.splent] features` and the page,
its sidebar entry and its script disappear together, with no other feature noticing.

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

## What it does

The feature is three files of substance: a blueprint, one route, one template. Its `__init__.py`
declares the blueprint and the `init_feature(app)` lifecycle hook that the loader calls at startup:

```python
team_bp = BaseBlueprint("team", __name__, template_folder="templates")


def init_feature(app: Flask) -> None:
    register_asset("js", "team.assets", subfolder="js", filename="scripts.js")
    register_nav_item("team", "Team", "/team", order=30, icon="users")
```

`register_nav_item` is how the sidebar gets its `Team` entry. The navigation is composed from the
features that actually loaded, not hardcoded in the layout: each feature declares its own entry and
the base template renders `get_nav_items()`. With `order=30`, `Team` sorts after `Home` (order 10,
from `public`) and `Explore` (order 20, from `explore`), and `users` is the feather icon shown next
to the label. Unload the feature and the sidebar entry is gone — nothing else references it.

`register_asset` declares the feature's script with the framework asset registry the same way; the
shared layout emits every registered `js` asset at the bottom of every page.

## Routes

| Endpoint | Methods | Rule |
|:---------|:--------|:-----|
| `team.index` | GET | `/team` |
| `team.assets` | GET | `/team/<subfolder>/<filename>` |

`team.index` is the entire `routes.py`: a single view that renders `team/index.html` with no
arguments. `team.assets` is not written by the feature at all — `BaseBlueprint` adds it automatically
because the feature has an `assets/` folder, and it serves files from that folder (here,
`/team/js/scripts.js`).

The page accepts GET only; a POST to `/team` answers 405. Confirm what is registered on a running
stack with:

```
rosemary route:list
```

## Models

None. The feature has no `models.py`, no `repositories.py`, no `forms.py`, no `seeders.py` and no
migration. Nothing it does touches the database.

## Services

None. The route renders the template directly; there is no `services.py` and no repository layer in
between. A static page does not need the full stack, and the feature does not carry it.

## Dependencies

Measured from the imports, in both directions:

- **From other features: nothing.** `routes.py` imports only Flask and the feature's own blueprint.
- **Into other features: nothing.** No file outside `app/features/team/` references the feature.

What it does import is the framework surface every feature uses:

```python
from splent_framework.blueprints.base_blueprint import BaseBlueprint
from splent_framework.assets.asset_registry import register_asset
from splent_framework.nav.nav_registry import register_nav_item
```

That is the whole dependency story. The coupling is zero in both directions, which is exactly the
shape the feature architecture aims for — most features cannot achieve it because their domain links
them to `dataset` or `auth`, but a self-contained page can.

## Templates and assets

`templates/team/index.html` extends `base_template.html` and fills the content block with a Bootstrap
card grid, one card per institution:

{% raw %}
```jinja
<div class="card h-100">
    <img src="{{ url_for('static', filename='img/logos/university_of_seville.svg') }}"
         class="card-img-top custom-img" alt="University of Seville">
    <div class="card-body custom-card-body">
        <h5 class="card-title">University of Seville, Spain</h5>
        ...
```
{% endraw %}

The university logos are not feature assets: they come from the app-level static folder
(`app/static/img/logos/`). Each card footer links to the institution's site with `target="_blank"`.

{: .note }
{% raw %}
The template's `{% block title %}` still says `View dataset` — a scaffold leftover — so the browser
tab on `/team` reads "View dataset", not "Team". The visible `<h1>` on the page is `Team`.
{% endraw %}

The one feature asset, `assets/js/scripts.js`, is a single `console.log` line. It exists to exercise
the asset registry pipeline rather than to do anything on the page.

## Tests

The feature tests exactly what it is: an HTTP layer, a browser layer and a load profile. There are no
unit, repository or service tests because there is no logic, no model and no service to test.

```
app/features/team/tests/
├── test_integration.py
├── test_selenium.py
└── locustfile.py
```

`test_integration.py` (`pytestmark = pytest.mark.integration`) drives the Flask test client: it
asserts the page answers 200 with all three institutions and their links in the HTML, and that the
route is public and GET-only (POST gets 405).

`test_selenium.py` (`pytestmark = pytest.mark.e2e`) runs against the live app and the Selenium grid
from `docker compose -f docker/docker-compose.dev.yml up`. Its four tests check that the page shows
one card per partner in order, that each card links to its own institution in a new tab, that the
page is reachable from the sidebar entry (which is marked active once there), and that an anonymous
visitor sees it without being redirected to `/login`. The page is static, so the whole file is
read-only and safe to repeat.

`locustfile.py` defines a `TeamUser` with a single task that GETs `/team` — one endpoint, one task.

```
rosemary test team --integration
rosemary test team --e2e
rosemary locust team
```

## Configuration

None. The feature has no `config.py`, no `.env.example`, and reads no environment variable. The only
configuration that concerns it is the feature selection itself: `team` is listed in the base
`[tool.splent] features` list of the root `pyproject.toml`, so it loads in every environment,
development and production alike. See
[Feature selection]({{site.baseurl}}/architecture/feature_selection).
