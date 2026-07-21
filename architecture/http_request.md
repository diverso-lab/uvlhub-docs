---
layout: default
title: HTTP Request
parent: Architecture
permalink: /architecture/http_request
nav_order: 3
---

# HTTP Request
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

![HTTP Request](/assets/images/http_request.svg)
*Figure 1: HTTP Request.*


The Figure 1 shows an HTTP request in {% include uvlhub.html %} using the Flask framework, organizing the code in a Model-View-Controller (MVC) pattern.


## Internet

The application is accessible through the internet.

## Server

A Flask server handles web requests and responses.

## Model-View-Controller (MVC)

Each feature in {% include uvlhub.html %} lives in its own package under `app/features/<feature>/` and holds a series of folders and files to handle HTTP requests, separating responsibility as indicated:

- *Model*. Represents the data and business logic of the application.
    - `models.py`: Defines the data structures and database interactions.
    - `repositories.py`: Implements functions to access and manipulate the data stored in the models.
    - `forms.py`: Defines forms and data validations that users can submit.
- *View*. Represents the user interface.
    - `templates/`: Contains the Jinja templates to generate the user interface.
    - `assets/js/`: Contains the client-side JavaScript for the feature, typically `scripts.js`.
- *Controller*. Handles the application logic and the communication between the model and the view.
    - `routes.py`: Defines the application routes, handling HTTP requests and determining which view should be rendered.
    - `services.py`: Implements the business logic and operations that belong neither to the model nor to the view.

Around that core, a feature also contains:

- `__init__.py`: Declares the feature's blueprint. This is the entry point that `app/feature_loader.py` imports and registers.
- `seeders.py`: Populates the database with the feature's development data.
- `tests/`: The feature's own test suite, one file per layer of the testing pyramid.
- `api.py`: Optional. Exposes the feature over the REST API.

Not every feature has every file. A read-only feature such as `team` is just `__init__.py`, `routes.py`, `templates/`, `assets/` and `tests/`, while `dataset` has all of them.

### `__init__.py`

The feature declares its blueprint here, using `BaseBlueprint` rather than Flask's own `Blueprint`:

```python
from splent_framework.blueprints.base_blueprint import BaseBlueprint

dataset_bp = BaseBlueprint("dataset", __name__, template_folder="templates")
```

`BaseBlueprint` resolves the feature's package directory and, if the feature has an `assets/` folder, automatically adds a route that serves files from it. That is what makes this work in a template:

```
{% raw %}<script src="{{ url_for('dataset.assets', subfolder='js', filename='scripts.js') }}"></script>{% endraw %}
```

Only the `js`, `css` and `dist` subfolders are served.

`__init__.py` may also define `init_feature(app)`, an optional lifecycle hook the loader calls with the application instance. The `auth` feature uses it to configure Flask-Login, so the central app factory stays feature-agnostic.

### `services.py`

Services extend `BaseService` from the framework:

```python
from splent_framework.services.BaseService import BaseService

from app.features.dataset.repositories import AuthorRepository


class AuthorService(BaseService):
    def __init__(self):
        super().__init__(AuthorRepository())
```

A service passes its primary repository up to `BaseService`, which exposes it as `self.repository` and provides the pass-through operations `create`, `count`, `get_by_id`, `get_or_404`, `update` and `delete`. A service that spans several models holds the extra repositories as its own attributes and adds the orchestration on top.

### `repositories.py`

Repositories extend `BaseRepository` from the framework, and bind themselves to one model:

```python
from splent_framework.repositories.BaseRepository import BaseRepository

from app.features.dataset.models import Author


class AuthorRepository(BaseRepository):
    def __init__(self):
        super().__init__(Author)
```

`BaseRepository` provides the common persistence operations, so a repository only has to add the queries specific to its model.

### `seeders.py`

Seeders extend `BaseSeeder` and implement `run()`. The `priority` attribute controls the order in which seeders execute, so a feature that depends on another feature's rows runs after it:

```python
from splent_framework.seeders.BaseSeeder import BaseSeeder


class DataSetSeeder(BaseSeeder):

    priority = 2  # Lower priority

    def run(self):
        ...
```

### `tests/`

Each feature keeps its tests next to the code they exercise, one file per layer:

| File | Marker | Layer |
|:--|:--|:--|
| `test_unit.py` | `unit` | Pure logic, no Flask app, no database |
| `test_repository.py` | `repository` | Repository against the database |
| `test_service.py` | `service` | Service-level with a real database |
| `test_integration.py` | `integration` | HTTP through the Flask test client |
| `test_selenium.py` | `e2e` | Browser-driven, against the Selenium Grid |
| `locustfile.py` | — | Load tests, driven by Locust |

Each pytest module sets the marker once at module level:

```python
import pytest

pytestmark = pytest.mark.e2e
```

`locustfile.py` is not a pytest module. The root `pyproject.toml` restricts collection to `test_*.py`, so Locust picks these files up directly instead.

### `api.py`

Optional. A feature that is exposed over the REST API declares its resources here and wires them into a Flask-RESTful `Api` bound to the feature blueprint. See `app/features/dataset/api.py`:

```python
def init_blueprint_api(api):
    """Function to register resources with the provided Flask-RESTful Api instance."""
    api.add_resource(DataSetResource, "/api/v1/datasets/", endpoint="datasets")
    api.add_resource(DataSetResource, "/api/v1/datasets/<int:id>", endpoint="dataset")
```

## Interaction and Data Flow

- Requests come to the Flask server from the Internet.
- The server dispatches these requests to the blueprint route registered from the feature's `routes.py`.
- `routes.py` calls `services.py` to perform business operations.
- `services.py` interacts with `repositories.py` to access data from `models.py` and the database.
- `forms.py` and the templates handle user input and generate the visual response that is sent back to the user through the Flask server.

## Database

- The database stores the persistent information of the application.
- `models.py` defines how this information is structured and accessed.

This architecture facilitates the separation of concerns, making the code more modular and easier to maintain. Each component has a clear and distinct responsibility, which improves the organization and scalability of the application.
