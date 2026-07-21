---
layout: default
title: splent_framework
parent: Architecture
permalink: /architecture/splent_framework
nav_order: 4
---

# splent_framework
{: .no_toc }

{% include uvlhub.html %} does not carry its own base classes. The pieces that every feature builds on top of come from `splent_framework`, an external package installed from PyPI like any other dependency.
{: .fs-6 .fw-300 }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

## Where it comes from

The framework is a normal pinned dependency in `requirements.txt`:

```
splent_framework==1.7.1
```

Installing the project's dependencies installs it:

```
pip install -r requirements.txt
```

{: .warning-title }
> The core package is gone
>
> There used to be a top-level `core/` package in the repository holding the base classes, the managers and the fixtures. It has been deleted. Anything that imported `from core...` now imports from `splent_framework` instead. If you are following an older guide or an older branch, translate the import path before you copy the code.

You can confirm what is installed from inside the running container:

```
docker exec web_app_container pip show splent_framework
```

## What it provides

These are the framework modules {% include uvlhub.html %} actually imports, and where each one is used.

| Import path | Used for |
|:--|:--|
| `splent_framework.services.BaseService` | Base class for every service in `app/features/<feature>/services.py` |
| `splent_framework.repositories.BaseRepository` | Base class for every repository in `app/features/<feature>/repositories.py` |
| `splent_framework.seeders.BaseSeeder` | Base class for every seeder in `app/features/<feature>/seeders.py` |
| `splent_framework.blueprints.base_blueprint` | `BaseBlueprint`, the blueprint every feature declares in its `__init__.py` |
| `splent_framework.db` | The shared SQLAlchemy instance, re-exported by `app/__init__.py` |
| `splent_framework.managers.config_manager` | `ConfigManager`, which loads configuration in the app factory |
| `splent_framework.managers.logging_manager` | `LoggingManager`, which sets up application logging |
| `splent_framework.managers.error_handler_manager` | `ErrorHandlerManager`, which registers the error pages |
| `splent_framework.managers.feature_manager` | `FeatureManager`, the SPL feature resolver. Not used by this product, see below |
| `splent_framework.configuration.configuration` | `get_app_version` and `uploads_folder_name` |
| `splent_framework.fixtures.fixtures` | The pytest fixtures re-exported by the root `conftest.py` |
| `splent_framework.environment.host` | `get_host_for_locust_testing`, used by every `locustfile.py` |
| `splent_framework.locust.common` | `get_csrf_token` and `fake`, used by the load tests |
| `splent_framework.bootstraps.locustfile_bootstrap` | The Locust bootstrap file, located by `rosemary locust` and by the Locust container entrypoint |
| `splent_framework.resources.generic_resource` | `create_resource`, used by `app/features/dataset/api.py` |
| `splent_framework.managers.jinja_manager` | `JinjaManager`, which installs the Jinja globals and the product context in the app factory |
| `splent_framework.assets.asset_registry` | `register_asset` / `get_assets`, how a feature declares its javascript and stylesheets |
| `splent_framework.nav.nav_registry` | `register_nav_item` / `get_nav_items`, how a feature declares its main-navigation entry |
| `splent_framework.settings.settings_schema` | `register_settings`, per-feature settings schemas. Not used by this product |
| `splent_framework.admin.registry` | `register_admin_resource`, the admin surface. Not used by this product |
| `splent_framework.serialisers.serializer` | `Serializer`, used to shape REST API responses |
| `splent_framework.utils.form_helpers` | `form_error` and `form_success` |

Every path in that table resolves in the running container. If you want to check one before you rely on it:

```
docker exec web_app_container python -c "import splent_framework.services.BaseService"
```

## The base classes

### BaseService

```python
from splent_framework.services.BaseService import BaseService
```

A service passes its primary repository up to `BaseService`, which stores it as `self.repository` and exposes the pass-through operations `create`, `count`, `get_by_id`, `get_or_404`, `update` and `delete`:

```python
class AuthorService(BaseService):
    def __init__(self):
        super().__init__(AuthorRepository())
```

That is the whole class. Anything beyond those six operations is business logic, and it belongs in your service.

### BaseRepository

```python
from splent_framework.repositories.BaseRepository import BaseRepository
```

A repository binds itself to exactly one model and inherits the common persistence operations, so it only has to add the queries specific to that model:

```python
class AuthorRepository(BaseRepository):
    def __init__(self):
        super().__init__(Author)
```

On top of the operations `BaseService` forwards, a repository also gets `get_by_column(column_name, value)` and `delete_by_column(column_name, value)`. `create` takes a `commit` flag, so you can build several rows in one transaction and commit once:

```python
author = self.create(commit=False, name="Ada")
```

### BaseSeeder

```python
from splent_framework.seeders.BaseSeeder import BaseSeeder
```

`BaseSeeder` is abstract. You implement `run()`, and you get `self.db` plus a `seed(data)` helper that bulk-inserts a list of instances of one model and returns them with their IDs populated. If the insert violates a constraint, `seed` rolls back and raises `SeederError` rather than leaving a half-written table behind.

```python
class DataSetSeeder(BaseSeeder):

    priority = 2

    def run(self):
        ...
```

{: .warning-title }
> priority is not a framework attribute
>
> `BaseSeeder` itself knows nothing about `priority`. Ordering is applied by Rosemary, which sorts the seeders it discovers with `getattr(seeder, "priority", 0)`. A seeder without the attribute sorts as `0` and runs first. Declare `priority` only when a seeder depends on rows another seeder creates.

### BaseBlueprint

```python
from splent_framework.blueprints.base_blueprint import BaseBlueprint

dataset_bp = BaseBlueprint("dataset", __name__, template_folder="templates")
```

`BaseBlueprint` is a Flask `Blueprint` that resolves the feature's package directory from its import name. If the feature has an `assets/` folder, it registers an asset route for it automatically, which is what makes this work from a template:

```
{% raw %}<script src="{{ url_for('dataset.assets', subfolder='js', filename='scripts.js') }}"></script>{% endraw %}
```

If you pass no `template_folder`, it falls back to the feature's own `templates/` directory.

## The shared database instance

`app/__init__.py` re-exports the framework's SQLAlchemy singleton:

```python
from splent_framework.db import db

__all__ = ["db", "create_app"]
```

That re-export is deliberate. Feature code can keep writing `from app import db` and still end up bound to the same instance that `BaseRepository` and `BaseSeeder` operate on. Creating a second `SQLAlchemy()` object would break `init_app` registration in a way that only surfaces at first query time, as an "app not registered with this instance" error.

## The managers

The managers are the framework's app-factory building blocks. `create_app` in `app/__init__.py` wires three of them, each with a single entry point:

```python
ConfigManager(app).load_config(config_name=config_name)
LoggingManager(app).setup_logging()
ErrorHandlerManager(app).register_error_handlers()
```

`FeatureManager` is the fourth, and {% include uvlhub.html %} does not use it at all. It reads the
feature list from `<WORKING_DIR>/<SPLENT_APP>/pyproject.toml`, which assumes the SPL workspace layout
where each product directory carries its own pyproject. This product keeps a single pyproject at the
repository root, so that lookup can never resolve.

Feature loading therefore goes through `app/feature_loader.py` instead, and `rosemary feature:list`
reads through the same module so the two cannot disagree.

Registration itself is done by the repository's own loader instead. See [Feature discovery](#feature-discovery) below.

## Test fixtures

The root `conftest.py` re-exports the framework's fixtures so every collected test picks them up:

```python
from splent_framework.fixtures.fixtures import (
    clean_database,
    test_app,
    test_client,
    test_client_module,
)
```

It also sets `SPLENT_APP=app` before that import, so the framework's app loader can resolve `create_app("testing")` without depending on your shell environment.

The four fixtures differ in how aggressively they reset the database. `test_client` drops and recreates every table before each test, so tests never see each other's rows. `test_client_module` resets once per module and lets the tests in that module share state, which is much faster when a module builds up a fixture set step by step. `clean_database` gives you a reset on demand inside a module-scoped run, and `test_app` is the session-scoped app the other three are built on.

## Things to know

A few framework behaviours are worth knowing before you reach for them, because they shape how this repository is wired.

### Selenium

Since 1.7.1 the framework itself can drive a Selenium Grid. `initialize_driver` attaches to the hub named by `SELENIUM_GRID_URL` through `webdriver.Remote`, so the browser runs in a grid node container; without that variable it launches a local browser through `webdriver_manager`, as before. It accepts chrome (the default) and firefox, chosen per call or through `SELENIUM_BROWSER`, and `get_host_for_selenium_testing` honours `SELENIUM_TARGET_URL` — needed because the URL a test opens is resolved *by the browser*, and inside a grid node `localhost` is the node itself.

The e2e layer still imports from the repository-local `tests/selenium_support.py`:

```python
from tests.selenium_support import close_driver, get_host_for_selenium_testing, initialize_driver
```

but that module is now a thin wrapper over the framework helpers. It defaults `SELENIUM_GRID_URL` and `SELENIUM_TARGET_URL` to this stack's container names when running under Docker, and pins a 1920x1080 window so the responsive layout is identical whichever browser the grid hands out. The driver itself comes from the framework.

The browser choice travels by environment variable: `rosemary selenium --driver firefox` sets `SELENIUM_BROWSER`, which the framework reads.

### Feature assets

The asset route `BaseBlueprint` registers serves only three subfolders: `js`, `css` and `dist`. Any other value of `subfolder` returns a 404 before the file is even looked up, so an `assets/img/logo.png` is not reachable through it. Resolved paths are also checked to stay inside the feature's asset directory, and anything escaping it returns a 403.

Today every feature under `app/features/` ships only an `assets/js/` folder, so the limit has not bitten yet. It will the first time a feature wants to serve something that is not a script, a stylesheet or a build output. Put those files under the application's shared static directory rather than the feature's `assets/`.

### The composition registries

1.7.0 introduced four process-global registries that let a feature contribute to the shell without
the shell knowing the feature exists. {% include uvlhub.html %} uses two of them.

**The asset registry.** A feature declares its script in `init_feature()`:

```python
def init_feature(app: Flask) -> None:
    register_asset("js", "team.assets", subfolder="js", filename="scripts.js")
```

`base_template.html` then emits every declared asset in one place, deduplicated and ordered:

```jinja
{% raw %}{% for asset in get_assets("js") %}
<script src="{{ asset }}"></script>
{% endfor %}{% endraw %}
```

Feature templates carry no `<script>` tags. There is a consequence worth knowing: **every feature's
script is served on every page**, so a script must be inert outside its own page. `explore` and
`dataset` check for an element of their own before wiring anything; the rest are placeholders.

**The nav registry.** A feature declares its main-navigation entry the same way:

```python
register_nav_item("explore", "Explore", "/explore", order=20, icon="search")
```

The sidebar iterates `get_nav_items()`, so removing a feature from `[tool.splent]` removes its link
rather than leaving a `url_for()` pointing at a blueprint that was never registered.

Only the unconditional public entries are registered. `register_nav_item` carries no visibility
condition, so the parts of the sidebar that depend on whether anyone is logged in stay in the
template.

`get_assets` reaches Jinja through `JinjaManager`; `get_nav_items` is registered as a global by
`app/__init__.py`, because the framework leaves the nav to whatever acts as the theme.

The other two registries, **settings** and **admin**, are unused here: this product has no per-feature
settings schema and no admin surface.

### Feature discovery

Feature registration is done by the repository's own `app/feature_loader.py`, not by the framework's `FeatureIntegrator`. The loader replicates the useful part of that contract — config injection, submodule import, `init_feature`, blueprint registration — without the SPL machinery, so there is no UVL constraint solving, no refinement registry and no namespaces. Which features load is declared in the root `pyproject.toml` under `[tool.splent]`.
