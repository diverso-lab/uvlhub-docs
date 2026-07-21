---
layout: default
title: C.R.U.D. tutorial
parent: Tutorials
permalink: /tutorials/crud_tutorial
nav_order: 1
---

# C.R.U.D. tutorial
{: .no_toc }

In this tutorial we are going to add the concept of a notepad (title and body) to our application. The logical steps are detailed as a first approach to the development of {% include uvlhub.html %}.
{: .fs-6 .fw-300 }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

Every command below runs inside the application container. Either open a shell once:

```
docker exec -it web_app_container bash
```

or prefix each command with `docker exec -it web_app_container`.

## Create a new feature

The unit of extension in {% include uvlhub.html %} is a **feature**: a self-contained package under
`app/features/`. We are going to create the `notepad` feature with the `Rosemary CLI`:

```
rosemary feature:create notepad
```

This creates `app/features/notepad/` with the blueprint, the three layers, a form, a seeder, a
template, an asset and six test files:

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

Take some time to examine each file and understand how they are related. The full breakdown of the
scaffold is on the [Create feature]({{site.baseurl}}/rosemary/extending_uvlhub/create_feature) page.

{: .note-title }
> How the script reaches the browser
>
> Notice that `templates/notepad/index.html` has no `<script>` tag. The generated `__init__.py`
> declares `assets/js/scripts.js` with `register_asset` in `init_feature`, and
> `base_template.html` renders every registered script from one place. You never write a
> per-feature `<script>` tag; the asset route only serves the `js`, `css` and `dist` subfolders
> of `assets/`.

### Declare the feature

Creating the folder is not enough. `app/feature_loader.py` only loads features declared in the root
`pyproject.toml`, so add `notepad` to `[tool.splent].features`:

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
```

{: .warning-title }
> Reboot required!
>
> Flask registers blueprints once, at startup. Even with the feature declared, the routes do not exist
> until the server restarts:
>
> ```
> docker restart web_app_container
> ```

Once the container is back up, list the routes of the feature:

```
rosemary route:list notepad
```

You should see something like this:

```
notepad.assets    GET    /notepad/<subfolder>/<filename>
notepad.index     GET    /notepad
```

## Model design

Let's make the `Notepad` model a bit more interesting. Let's add two fields and an owner user.

The `app/features/notepad/models.py` file would look like this:

```python
from app import db


class Notepad(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(256), nullable=False)
    body = db.Column(db.Text, nullable=False)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)

    user = db.relationship('User', backref='notepads', lazy=True)

    def __repr__(self):
        return f'Notepad<{self.id}, Title={self.title}, Author={self.user.email}>'
```

{: .note-title }
> Users are identified by email
>
> The `User` model in `app/features/auth/models.py` has `email`, not `username`. Reaching for
> `self.user.username` raises `AttributeError` at the first `repr()`.

## Inclusion of dependencies

Since this is your first time developing this project, it can be a bit confusing to manage
dependencies.

Before you continue, make sure that **at the beginning of the `routes.py`** file you have the
following content:

```python
from flask import render_template, redirect, url_for, flash
from flask_login import login_required, current_user
from splent_framework.utils.form_helpers import form_error, form_success

from app.features.notepad import notepad_bp
from app.features.notepad.forms import NotepadForm
from app.features.notepad.services import NotepadService

notepad_service = NotepadService()
```

`form_error` and `form_success` are small presentation helpers shipped by `splent_framework`. They do
exactly what their names say, and nothing more:

```python
def form_success(endpoint, message, category="success", **url_kwargs):
    flash(message, category)
    return redirect(url_for(endpoint, **url_kwargs))


def form_error(template, form, errors=None, **context):
    for field, messages in (errors or {}).items():
        for msg in messages:
            flash(f"{field}: {msg}", "error")
    return render_template(template, form=form, **context)
```

They live in the framework rather than on `BaseService` because they are HTTP concerns. Services
return data, routes turn data into responses. `app/features/profile/routes.py` and
`app/features/auth/routes.py` are the reference uses.

## Default route: list all my notepads

It's a bit boring to work only with code and not see anything, so let's do something interesting!
Let's re-define the `/notepad` route to list the notepads created by me (even if we don't have any
yet).

### Define the route in `routes.py`

```python
'''
READ ALL
'''
@notepad_bp.route('/notepad', methods=['GET'])
@login_required
def index():
    form = NotepadForm()
    notepads = notepad_service.get_all_by_user(current_user.id)
    return render_template('notepad/index.html', notepads=notepads, form=form)
```

### Define the template `app/features/notepad/templates/notepad/index.html`

```jinja
{% raw %}{% extends "base_template.html" %}

{% block title %}View my notepads{% endblock %}

{% block content %}

{% with messages = get_flashed_messages(with_categories=true) %}
  {% if messages %}
    {% for category, message in messages %}
      <div class="alert alert-{{ category }}" role="alert">{{ message }}</div>
    {% endfor %}
  {% endif %}
{% endwith %}

<a href="{{ url_for('notepad.create_notepad') }}">New notepad</a>

{% if notepads %}
    <ul>
    {% for notepad in notepads %}
        <li>
            <strong><a href="{{ url_for('notepad.get_notepad', notepad_id=notepad.id) }}">{{ notepad.title }}</a></strong> - {{ notepad.body }}
            <a href="{{ url_for('notepad.edit_notepad', notepad_id=notepad.id) }}">Edit</a>
            <form method="POST" action="{{ url_for('notepad.delete_notepad', notepad_id=notepad.id) }}">
                {{ form.hidden_tag() }}
                <button type="submit">Delete</button>
            </form>
        </li>
    {% endfor %}
    </ul>
{% else %}
    <p>You have no notepads.</p>
{% endif %}

{% endblock %}{% endraw %}
```

The `get_flashed_messages` block matters: `base_template.html` does not render flash messages for you,
so a template that never asks for them will silently swallow every success and error message.

{: .note-title }
> This template links forward
>
> `create_notepad`, `get_notepad`, `edit_notepad` and `delete_notepad` are written further down, in
> the [Complete C.R.U.D.](#complete-crud) section. Until they exist, `url_for` raises
> `BuildError: Could not build url for endpoint 'notepad.create_notepad'`. Either comment out the
> links for now, or write the four routes before you load the page.

### Add new function in NotepadService

The `app/features/notepad/services.py` file should look like this:

```python
from app.features.notepad.repositories import NotepadRepository
from splent_framework.services.BaseService import BaseService


class NotepadService(BaseService):
    def __init__(self):
        super().__init__(NotepadRepository())

    def get_all_by_user(self, user_id):
        return self.repository.get_all_by_user(user_id)
```

`BaseService` comes from the `splent_framework` package and gives you `create`, `count`, `get_by_id`,
`get_or_404`, `update` and `delete`, all delegating to the repository. Anything beyond that is yours
to write.

### Add new function in NotepadRepository

The `app/features/notepad/repositories.py` file should look like this:

```python
from app.features.notepad.models import Notepad
from splent_framework.repositories.BaseRepository import BaseRepository


class NotepadRepository(BaseRepository):
    def __init__(self):
        super().__init__(Notepad)

    def get_all_by_user(self, user_id):
        return self.get_by_column('user_id', user_id)
```

`BaseRepository` already ships `get_by_column`, so filtering by owner is one line. Write the query by
hand only when the base class has nothing that fits.

We go to the `/notepad` route in the browser. Since we use the middleware `@login_required`, it is
necessary to log in using a test user:

```
User: user1@example.com
Pass: 1234
```

If we access `/notepad` we notice that it gives error. Why do you think it gives error?

## Migrations

Even if you define a model, it does not automatically exist in the database. You need to update the
database, but don't even think of creating a table by hand! No, that's what migrations are for.

{: .note-title }
> <i class="fa-solid fa-code"></i> Concept of a migration
>
> A migration is a software artefact that details how a database evolves, i.e. how it migrates from one state to another.

### Create a new migration

Since we have a new entity in our model, in this case `Notepad`, it is necessary to create a new
migration:

```
flask db migrate -m "create_notepad_model"
```

This creates a file in `migrations/versions/XXXXXXXXX_create_notepad_model.py`, with `XXXXXXXXX`
being a unique alphanumeric revision identifier. Take your time to read this file: autogeneration is
a good first draft, not an oracle.

Let's go back to the `/notepad` route and see that it **still** gives an error. Why do you think it
happens, if we have already created a new migration?

### Apply the new migration

It is important to understand that the above command has only created the migration file, but we have
not executed it yet. To run new migrations:

```
flask db upgrade
```

We go to the `/notepad` route and see that it no longer gives an error. Excellent!

## Design form

We are going to design a form thanks to the Flask-WTForms package.

{: .note-title }
> <i class="fa-solid fa-code"></i> Flask-WTForms
>
> Flask-WTForms is a Flask extension that allows you to manage and validate forms in an efficient and structured way within Flask web applications. It combines the simplicity of HTML forms with the advantages of server-side data validation, all in a simple and reusable way.

The `app/features/notepad/forms.py` file must have this content:

```python
from flask_wtf import FlaskForm
from wtforms import StringField, TextAreaField, SubmitField
from wtforms.validators import DataRequired, Length


class NotepadForm(FlaskForm):
    title = StringField('Title', validators=[DataRequired(), Length(max=256)])
    body = TextAreaField('Body', validators=[DataRequired()])
    submit = SubmitField('Save notepad')
```

## Complete C.R.U.D.

With all that we have learned and thanks to the form, we are ready to design a complete C.R.U.D.

### Create a notepad

#### Route in `routes.py`

```python
'''
CREATE
'''
@notepad_bp.route('/notepad/create', methods=['GET', 'POST'])
@login_required
def create_notepad():
    form = NotepadForm()
    if form.validate_on_submit():
        notepad_service.create(
            title=form.title.data,
            body=form.body.data,
            user_id=current_user.id,
        )
        return form_success('notepad.index', 'Notepad created successfully!')
    if form.errors:
        return form_error('notepad/create.html', form, form.errors)
    return render_template('notepad/create.html', form=form)
```

#### Template `app/features/notepad/templates/notepad/create.html`

```jinja
{% raw %}{% extends "base_template.html" %}

{% block title %}Create notepad{% endblock %}

{% block content %}

<form method="POST" action="{{ url_for('notepad.create_notepad') }}">
    {{ form.hidden_tag() }}
    <div>
        {{ form.title.label }}<br>
        {{ form.title(size=32) }}
    </div>
    <div>
        {{ form.body.label }}<br>
        {{ form.body(rows=5) }}
    </div>
    <div>
        {{ form.submit() }}
    </div>
</form>

{% endblock %}{% endraw %}
```

### Read a notepad

#### Route in `routes.py`

```python
'''
READ BY ID
'''
@notepad_bp.route('/notepad/<int:notepad_id>', methods=['GET'])
@login_required
def get_notepad(notepad_id):
    notepad = notepad_service.get_or_404(notepad_id)

    if notepad.user_id != current_user.id:
        flash('You are not authorized to view this notepad', 'error')
        return redirect(url_for('notepad.index'))

    return render_template('notepad/show.html', notepad=notepad)
```

`get_or_404` is inherited from `BaseService`, which delegates to `BaseRepository.get_or_404`. An
unknown id aborts with a 404 before your ownership check ever runs.

#### Template `app/features/notepad/templates/notepad/show.html`

```jinja
{% raw %}{% extends "base_template.html" %}

{% block title %}Notepad details{% endblock %}

{% block content %}

<h1>{{ notepad.title }}</h1>
<p>{{ notepad.body }}</p>
<a href="{{ url_for('notepad.index') }}">Back to Notepads</a>
{% endblock %}{% endraw %}
```

### Edit a notepad

#### Route in `routes.py`

```python
'''
EDIT
'''
@notepad_bp.route('/notepad/edit/<int:notepad_id>', methods=['GET', 'POST'])
@login_required
def edit_notepad(notepad_id):
    notepad = notepad_service.get_or_404(notepad_id)
    if notepad.user_id != current_user.id:
        flash('You are not authorized to edit this notepad', 'error')
        return redirect(url_for('notepad.index'))

    form = NotepadForm(obj=notepad)
    if form.validate_on_submit():
        notepad_service.update(
            notepad_id,
            title=form.title.data,
            body=form.body.data,
        )
        return form_success('notepad.index', 'Notepad updated successfully!')
    if form.errors:
        return form_error('notepad/edit.html', form, form.errors, notepad=notepad)
    return render_template('notepad/edit.html', form=form, notepad=notepad)
```

#### Template `app/features/notepad/templates/notepad/edit.html`

```jinja
{% raw %}{% extends "base_template.html" %}

{% block title %}Edit notepad{% endblock %}

{% block content %}

<form method="POST" action="{{ url_for('notepad.edit_notepad', notepad_id=notepad.id) }}">
    {{ form.hidden_tag() }}
    <div>
        {{ form.title.label }}<br>
        {{ form.title(size=32) }}
    </div>
    <div>
        {{ form.body.label }}<br>
        {{ form.body(rows=5) }}
    </div>
    <div>
        {{ form.submit() }}
    </div>
</form>

{% endblock %}{% endraw %}
```

### Delete a notepad

#### Route in `routes.py`

```python
'''
DELETE
'''
@notepad_bp.route('/notepad/delete/<int:notepad_id>', methods=['POST'])
@login_required
def delete_notepad(notepad_id):
    notepad = notepad_service.get_or_404(notepad_id)
    if notepad.user_id != current_user.id:
        flash('You are not authorized to delete this notepad', 'error')
        return redirect(url_for('notepad.index'))

    if notepad_service.delete(notepad_id):
        return form_success('notepad.index', 'Notepad deleted successfully!')

    return form_success('notepad.index', 'Error deleting notepad', category='error')
```

`BaseRepository.delete` returns `True` when a row was removed and `False` when the id did not match
anything, which is why the return value is worth branching on.

Take the time to check that everything is working properly. Try creating a notepad in the
`/notepad/create` route.

You can list the routes again to see that they have been updated:

```
rosemary route:list notepad
```

## Fill in the tests

`feature:create` already handed you `app/features/notepad/tests/`, with one file per layer of the
testing pyramid. The five `test_*.py` files are each pre-tagged with their marker at module level;
`locustfile.py` is driven by `rosemary locust` rather than pytest. They are stubs, and now you have
something worth asserting on.

Start with `tests/test_integration.py`. The generated stub asserts that `GET /notepad` returns 200,
which stopped being true the moment you added `@login_required` — the route now answers with a
redirect to the login page. Make the test say so:

```python
import pytest

pytestmark = pytest.mark.integration


def test_notepad_index_requires_login(test_client):
    response = test_client.get("/notepad", follow_redirects=False)
    assert response.status_code in (302, 303)
    assert "/login" in response.headers["Location"]
```

Then `tests/test_service.py`, where the database is real but there is no HTTP:

```python
import pytest

from app.features.auth.repositories import UserRepository
from app.features.notepad.services import NotepadService

pytestmark = pytest.mark.service


def test_get_all_by_user_only_returns_own_notepads(test_app):
    with test_app.app_context():
        service = NotepadService()
        mine = UserRepository().create(email="mine@example.com", password="secret")
        theirs = UserRepository().create(email="theirs@example.com", password="secret")

        service.create(title="Mine", body="...", user_id=mine.id)
        service.create(title="Theirs", body="...", user_id=theirs.id)

        notepads = service.get_all_by_user(mine.id)

        assert [n.title for n in notepads] == ["Mine"]
```

The `test_client` and `test_app` fixtures come from `splent_framework.fixtures.fixtures` and are
re-exported by the root `conftest.py`, so you never import them yourself.

Run the fast layers for your feature:

```
rosemary test notepad
```

That runs the `unit`, `repository`, `service` and `integration` markers. Add `--e2e` for the browser
layer once you have written `test_selenium.py` against the Selenium grid, and use `rosemary locust`
for the load layer.

Happy development!
