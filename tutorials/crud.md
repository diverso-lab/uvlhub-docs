---
layout: default
title: C.R.U.D. tutorial
parent: Tutorials
permalink: /tutorials/crud_tutorial
nav_order: 1
---

# C.R.U.D. tutorial
{: .no_toc }

In this tutorial we are going to add the concept of a notepad (title and description) to our application. The logical steps are detailed as a first approach to the development of {% include uvlhub.html %}.
{: .fs-6 .fw-300 }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

## Create a new module

We are going to create the `notepad` module. To do this, we are going to use the `Rosemary CLI`:

```
rosemary make:module notepad
```

This creates a folder in `app/modules/notepad` with several files inside. Take some time to examine each file and understand how they are related.

### Dynamic loading of modules

If we would like to check if the module is already listed by the system, we apply:

```
rosemary module:list
```

{: .warning-title }
> Reboot required!
> 
> However, we are not going to see our module there since Flask has a particular way of loading files and modules. We have to **restart** our Flask server (or the Docker container). After that, our module should be listed.
>

We can also list the current routes of our module with:

```
rosemary route:list notepad
```

We should see something like this:

```
notepad.index           GET         /notepad  
```

## Model design

Let's make the `Notepad` model a bit more interesting. Let's add two fields and add an owner user.

The `app/modules/notepad/models.py` file would look like this:

```python
from app import db

class Notepad(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(256), nullable=False)
    body = db.Column(db.Text, nullable=False)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)

    user = db.relationship('User', backref='notepads', lazy=True)

    def __repr__(self):
        return f'Notepad<{self.id}, Title={self.title}, Author={self.user.username}>'
```

## Inclusion of dependencies

Since this is your first time developing this project, it can be a bit confusing to manage dependencies.

Before you continue, make sure that **at the beginning of the `routes.py`** file you have the following content:

```python
from flask import render_template, redirect, url_for, flash, request
from flask_login import login_required, current_user

from app.modules.notepad.forms import NotepadForm
from app.modules.notepad import notepad_bp
from app.modules.notepad.services import NotepadService

notepad_service = NotepadService()
```

## Default route: list all my notepads

It's a bit boring to work only with code and not see anything, so let's do something interesting! Let's re-define the `/notepad` route to list the notepads created by me (even if we don't have any yet).

### Define the route

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

### Define the template `notepad/templates/notepad/index.html`

```jinja
{% raw %}
{% extends "base_template.html" %}

{% block title %}View my notepads{% endblock %}

{% block content %}

{% if notepads %}
    <ul>
    {% for notepad in notepads %}
        <li>
            <strong><a href="{{ url_for('notepad.edit_notepad', notepad_id=notepad.id) }}">{{ notepad.title }}</a></strong> - {{ notepad.body }}
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

{% endblock %}

{% block scripts %}
    <script src="{{ url_for('notepad.scripts') }}"></script>
{% endblock %}
{% endraw %}
```

We go to the `/notepad` route in the browser and see that it gives an error. Why do you think it gives an error?

## Migrations

Even if you define a model, it does not automatically exist in the database. You need to update the database, but don't even think of creating a table by hand! No, that's what migrations are for.

{: .note-title }
> <i class="fa-solid fa-code"></i> Concept of a migration
>
> A migration is a software artefact that details how a database evolves, i.e. how it migrates from one state to another.
 
### Create a new migration

Since we have a new entity in our model, in this case `Notepad`, it is necessary to create a new migration:

```
flask db migrate -m "create_notepad_model"
```

This creates a file in `migrations/versions/XXXXXXXXX_create_notepad_model` with `XXXXXXXXX` being a unique alphanumeric string generated via the timestamp. Take your time to parse this file.

Let's go back to the `/notepad` path and see that it **still** gives an error. Why do you think it happens, if we have already created a new migration?

### Apply the new migration

It is important to understand that the above command has only created the migration file, but we have not executed it yet. To run new migrations:
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

The `notepad/forms.py` file must have this content:

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

#### Route

```python
'''
CREATE
'''
@notepad_bp.route('/notepad/create', methods=['GET', 'POST'])
@login_required
def create_notepad():
    form = NotepadForm()
    if form.validate_on_submit():
        result = notepad_service.create(title=form.title.data, body=form.body.data, user_id=current_user.id)
        return notepad_service.handle_service_response(
            result=result,
            errors=form.errors,
            success_url_redirect='notepad.index',
            success_msg='Notepad created successfully!',
            error_template='notepad/create.html',
            form=form
        )
    return render_template('notepad/create.html', form=form)
```

#### Template `notepad/templates/notepad/create.hml`

```jinja
{% raw %}
{% extends "base_template.html" %}

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


{% endblock %}

{% block scripts %}
    <script src="{{ url_for('notepad.scripts') }}"></script>
{% endblock %}
{% endraw %}
```

### Read a notepad

#### Route

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

#### Template `notepad/templates/notepad/show.hml`

```jinja
{% raw %}
{% extends "base_template.html" %}

{% block title %}Notepad details{% endblock %}

{% block content %}

<h1>{{ notepad.title }}</h1>
<p>{{ notepad.body }}</p>
<a href="{{ url_for('notepad.index') }}">Back to Notepads</a>
{% endblock %}

{% block scripts %}
    <script src="{{ url_for('notepad.scripts') }}"></script>
{% endblock %}
{% endraw %}
```

### Edit a notepad

#### Route

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
        result = notepad_service.update(
            notepad_id,
            title=form.title.data,
            body=form.body.data
        )
        return notepad_service.handle_service_response(
            result=result,
            errors=form.errors,
            success_url_redirect='notepad.index',
            success_msg='Notepad updated successfully!',
            error_template='notepad/edit.html',
            form=form
        )
    return render_template('notepad/edit.html', form=form, notepad=notepad)
```

#### Template `notepad/templates/notepad/edit.hml`

```jinja
{% raw %}
{% extends "base_template.html" %}

{% block title %}View notepad{% endblock %}

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

{% endblock %}

{% block scripts %}
    <script src="{{ url_for('notepad.scripts') }}"></script>
{% endblock %}

{% endraw %}
```

### Delete a notepad

#### Route

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

    result = notepad_service.delete(notepad_id)
    if result:
        flash('Notepad deleted successfully!', 'success')
    else:
        flash('Error deleting notepad', 'error')
    
    return redirect(url_for('notepad.index'))

```

Take the time to check that everything is working properly. Happy development!