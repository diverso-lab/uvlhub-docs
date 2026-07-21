---
layout: default
title: Feature selection
parent: Architecture
permalink: /architecture/feature_selection
nav_order: 5
---

# Feature selection
{: .no_toc }

Which features the application loads is declared in one place: the `[tool.splent]` table of the root `pyproject.toml`. Nothing is discovered by convention alone, and nothing is switched off by deleting files.
{: .fs-6 .fw-300 }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

## The contract

`[tool.splent]` holds three lists. This is the real content of the root `pyproject.toml`:

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
features_prod = [
    "webhook",
]
```

Each entry is a directory name under `app/features/`. The three lists mean:

| List | Meaning |
|:--|:--|
| `features` | The base set. Loaded in every environment. |
| `features_dev` | Added on top of the base set when the environment resolves to `dev`. |
| `features_prod` | Added on top of the base set when the environment resolves to `prod`. |

The lists are additive. There is no "exclude" list: a feature is absent from an environment because it was never added to it, not because something removed it.

{: .important-title }
> The lists are the only selection mechanism
>
> The three lists above are the only place features are selected. There is no per-machine file to edit and no runtime switch: if a feature is not named in a list that applies to the environment, it is not loaded.

## How the loader resolves the lists

`app/feature_loader.py` owns the whole mechanism. Its entry point is `register_features`, called once from the application factory in `app/__init__.py`:

```python
env = "prod" if config_name == "production" else "dev"
register_features(app, env=env)
```

So the environment string is derived from the `config_name` passed to `create_app`. It is `prod` for exactly one value, `production`, and `dev` for everything else, including `development` and `testing`.

`register_features` then resolves the declared set as a union:

```python
base = splent.get("features") or []
env_list = splent.get(f"features_{env}") or []
return set(base) | set(env_list)
```

Note the interpolation: with `env="dev"` the loader reads the key `features_dev`, with `env="prod"` it reads `features_prod`. Adding a `features_staging` list would do nothing unless something creates the app with a `staging` config name.

Resolving today's `pyproject.toml` gives:

| Environment | Features loaded |
|:--|:--|
| `dev` | the ten base features, plus `webhook` |
| `prod` | the ten base features |

You can check the resolved set for an environment without starting the app:

```
python3 -c "import tomllib; s=tomllib.load(open('pyproject.toml','rb'))['tool']['splent']; print(sorted(set(s['features']) | set(s['features_dev'])))"
```

Swap `features_dev` for `features_prod` to see the production set.

### When a list is empty

Two different empty cases behave differently, and the distinction matters.

An empty environment list is unremarkable: it simply contributes nothing to the union, so that environment gets the base set and no more. Removing the key entirely has the same effect, because `splent.get(...) or []` treats a missing key and an empty list identically.

An empty *result* turns the filter off completely. The loader only filters when it has something to filter with:

```python
if declared and name not in declared:
    continue
```

If `features` and the environment list are both empty or absent, `declared` is an empty set, the condition is false for every candidate, and **every package found under `app/features/` is loaded**. This is a deliberate fallback so a bare playground app works without ceremony, but it is a sharp edge: emptying `features` does not disable all features, it enables all of them. To stop one feature from loading, remove that one name and leave the rest of the list in place.

### What the loader iterates

The loader walks the packages that actually exist on disk and skips the ones not declared, rather than walking the declared names:

```python
for _, name, ispkg in pkgutil.iter_modules(features_pkg.__path__):
```

Two consequences follow from this direction:

- A package sitting in `app/features/` that is named in no list is silently skipped. It stays in the repository and on the Python path, but no routes, models or blueprints of it reach the app.
- A name listed in `[tool.splent]` with no matching directory is silently ignored. There is no error and no warning, so a typo in the list looks exactly like a feature that quietly failed to appear.

Load order follows `pkgutil.iter_modules`, which is alphabetical by directory name. The order you write names in the TOML lists has no effect. Do not rely on one feature being registered before another.

## The per-feature lifecycle

For every selected feature, in order, the loader does four things. All four steps are optional from the feature's side: a feature that provides none of these hooks still loads, it just contributes nothing at that step.

### 1. Config injection

```python
importlib.import_module(f"app.features.{name}.config")
```

If the feature has a `config.py` exposing a callable `inject_config(app)`, it is called first, before anything else touches the app. A missing `config.py` raises `ModuleNotFoundError`, which the loader catches and ignores. This step runs first so a feature can mutate `app.config` before its own models and routes are imported.

### 2. Importing the conventional submodules

The feature package itself is imported, then these four submodules are imported if they exist:

```python
_SUBMODULES = ("routes", "models", "hooks", "signals")
```

Each is attempted individually and a `ModuleNotFoundError` is swallowed, so a feature declares only the ones it needs. The point of this step is side effects: importing `routes` is what attaches view functions to the blueprint, and importing `models` is what registers the SQLAlchemy mappings so migrations can see them.

### 3. `init_feature`

```python
fn = getattr(feature_module, "init_feature", None)
if callable(fn):
    fn(app)
```

If the feature's `__init__.py` defines `init_feature(app)`, the loader calls it with the app instance. This is the hook for setup that needs a live app but does not belong in the central factory. In {% include uvlhub.html %} every feature defines one: each registers its `assets/js/scripts.js` in the framework's asset registry, and `public`, `explore` and `team` additionally register their sidebar entries. `auth` goes furthest, using the hook to wire up Flask-Login as well:

```python
def init_feature(app: Flask) -> None:
    register_asset("js", "auth.assets", subfolder="js", filename="scripts.js")

    login_manager = LoginManager()
    login_manager.init_app(app)
    login_manager.login_view = "auth.login"

    @login_manager.user_loader
    def load_user(user_id):
        from app.features.auth.models import User

        return User.query.get(int(user_id))
```

That code lives in `app/features/auth/__init__.py` rather than in `create_app`, which is what keeps the application factory free of any knowledge about individual features.

### 4. Blueprint registration

Finally the loader collects every Flask `Blueprint` instance it can see on the feature package and on the four submodules it imported, and registers each one:

```python
if isinstance(obj, Blueprint) and obj.name not in seen:
    app.register_blueprint(obj)
    seen.add(obj.name)
```

The `seen` set is per feature, and it exists because the same blueprint object is normally visible from two places. A feature declares its blueprint in `__init__.py`:

```python
webhook_bp = BaseBlueprint("webhook", __name__, template_folder="templates")
```

and its `routes.py` imports that object to hang routes off it:

```python
from app.features.webhook import webhook_bp
```

so the identical `Blueprint` shows up as an attribute of both modules. Deduplicating by `obj.name` stops the loader from registering it twice.

## What this means in practice: the webhook feature

`webhook` is listed in both environment lists, which is itself a statement: the feature is wanted
everywhere, but for different reasons — its test suite in development, the continuous-deployment
endpoint in production:

```toml
features_dev = [
    "webhook",
]
features_prod = [
    "webhook",
]
```

A feature listed in only one of them is the environment-split case: declared once, resolved per
environment, no per-machine configuration anywhere.

Because the application factory maps both `development` and `testing` to `dev`, the feature is registered when you run the app locally and when the test suite builds an app through `create_app("testing")`. Its routes exist, its tests run, and it behaves like any other feature.

Under an app created with `config_name="production"`, `env` is `prod`, the loader reads `features_prod`, and `webhook` is not in the resolved set. The directory is still present in the image, but the loader walks past it: no config injection, no `routes` import, no blueprint. The endpoint is not merely protected, it does not exist, so requests to it get a 404 from the routing layer.

Nobody edits a file to make that happen at deploy time. The environment split is a property of the contract itself: the lists describe every environment at once and travel with the source, so the same checkout behaves correctly wherever it is deployed.

{: .note-title }
> How the deployment path selects the set
>
> The module-level `app = create_app(...)` that gunicorn imports passes `FLASK_ENV` as the config name, and the values in the env examples (`development`, `production`, `testing`) are exactly the names `ConfigManager` accepts. With `FLASK_ENV=production`, as `.env.docker.production.example` sets, `env` resolves to `prod` and the loader reads `features` plus `features_prod`, so `webhook` is not registered. Earlier revisions always built the development config here regardless of environment, which is worth knowing when comparing against an old checkout.

## Verifying what actually loaded

The TOML lists are the declaration. To see what a running app really registered, list its routes:

```
rosemary route:list --group
```

That prints every registered endpoint with its methods and URL rule, grouped by the endpoint prefix, which is the blueprint name. Since each feature declares its blueprint after itself, a feature that failed to load shows up as a missing block rather than as an error message. Given how quietly the loader skips a mistyped name or a missing submodule, this is the check worth running after any change to `[tool.splent]`.
