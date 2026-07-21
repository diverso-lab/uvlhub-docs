---
layout: default
parent: Features
title: auth
permalink: /features/auth
nav_order: 1
---

# auth
{: .no_toc }

The `auth` feature owns user identity: it defines the `User` model, the signup, login and logout
routes, and the password hashing that goes with them. Signup collects an email, a password, a name
and a surname; the email must not be in use, and on success the user is created together with a
`UserProfile` row in a single transaction (`AuthenticationService.create_with_profile`), logged in
immediately with a remembered session, and redirected to the landing page. Login checks the email
and password against the stored hash and calls Flask-Login's `login_user`; logout calls
`logout_user` and redirects home.

Beyond its own routes, `auth` makes a shell contribution the whole application relies on: its
`init_feature(app)` configures Flask-Login. It creates the `LoginManager`, sets
`login_manager.login_view = "auth.login"` and registers the `user_loader` that resolves session ids
back to `User` rows. Every `@login_required` view in every other feature works because `auth` is
loaded — an anonymous request to a protected page is redirected to `/login` by this configuration.
The docstring in `app/features/auth/__init__.py` states the intent: login is an auth concern, not a
product concern, so the wiring lives here and the central app factory stays feature-agnostic.

Passwords are never stored in plain text. `User.__init__` intercepts the `password` kwarg and runs
it through `werkzeug.security.generate_password_hash`; `check_password` verifies against the hash.
The repository's `create` does the same for users created through the service layer.

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

## Routes

From `rosemary route:list` on the running stack:

| Endpoint | Methods | Rule |
|:---------|:--------|:-----|
| `auth.show_signup_form` | GET, POST | `/signup/` |
| `auth.login` | GET, POST | `/login` |
| `auth.logout` | GET | `/logout` |
| `auth.assets` | GET | `/auth/<subfolder>/<filename>` |

`/signup/` and `/login` both redirect an already-authenticated user straight to `public.index`.
Failed attempts re-render the form through `form_error` with a field-level message: `"<email> in
use"` on signup, `"Invalid credentials"` on login. `auth.assets` is the per-feature static route
every `BaseBlueprint` gets; it serves the files under `app/features/auth/assets/`.

## Models

`app/features/auth/models.py` defines one model:

| Column | Type | Notes |
|:-------|:-----|:------|
| `id` | Integer | Primary key. |
| `email` | String(256) | Unique, not null. |
| `password` | String(256) | Werkzeug hash, never the plain value. |
| `created_at` | DateTime | Not null, defaults to the current UTC time. |

`User` mixes in Flask-Login's `UserMixin` and carries two relationships: `data_sets` (the user's
`DataSet` rows, backref `user`) and `profile` (a one-to-one `UserProfile`, `uselist=False`). It also
exposes `set_password`, `check_password` and `temp_folder()`, which delegates to
`AuthenticationService.temp_folder_by_user` to compute the per-user upload staging directory.

## Services and repositories

`AuthenticationService` extends `BaseService` over a `UserRepository`:

| Method | Purpose |
|:-------|:--------|
| `login(email, password, remember=True)` | Verifies credentials and calls `login_user`. Returns a boolean. |
| `is_email_available(email)` | `True` if no user has that email. |
| `create_with_profile(**kwargs)` | Creates the `User` and its `UserProfile` in one transaction; rolls back both on any failure. Requires email, password, name and surname. |
| `get_authenticated_user()` | The current `User`, or `None` when anonymous. |
| `get_authenticated_user_profile()` | The current user's `UserProfile`, or `None`. |
| `temp_folder_by_user(user)` | `<uploads>/temp/<user_id>`, the staging folder the dataset upload flow uses. |

`UserRepository` extends `BaseRepository` and adds `get_by_email` plus a `create` override that pops
the `password` kwarg and hashes it via `set_password`, with a `commit=False` mode (flush only) that
`create_with_profile` uses to get the new user's id before committing user and profile together.

## Seeders

`app/features/auth/seeders.py` defines `AuthSeeder` with `priority = 1`, so it runs before seeders
of features that need users to exist. It seeds two accounts:

| Email | Password | Profile |
|:------|:---------|:--------|
| `user1@example.com` | `1234` | John Doe, Some University |
| `user2@example.com` | `1234` | Jane Doe, Some University |

The seeder creates the `UserProfile` rows itself (importing `profile.models` directly), reusing the
ids returned by `self.seed(users)`. These accounts are what the e2e tests and the locustfile log in
with.

## Dependencies

Measured from the production code (imports, tests excluded):

| Edge | Where | What it means |
|:-----|:------|:--------------|
| `auth` → `profile.models` | `services.py`, `seeders.py` | `create_with_profile` and `AuthSeeder` construct `UserProfile` rows directly. |
| `auth` → `profile.repositories` | `services.py` | `AuthenticationService` holds a `UserProfileRepository` and writes profiles through it — a cross-feature service-to-repository reach that bypasses profile's own service layer. |
| `auth` → `profile.services` | `routes.py` | `routes.py` imports and instantiates `UserProfileService` at import time (no route currently calls it, but the import binds the features together at load). |

Inbound, `dataset`, `hubfile` and `profile` all import from `auth` at module level — `dataset` and
`hubfile` for the `User` model (and `dataset.services` for `AuthenticationService`), `profile` for
`AuthenticationService` in its routes. At the schema level, `user_profile.user_id` is a foreign key
to auth's `user` table, and many other features' tables carry a `user.id` foreign key as well.

The practical consequence: **`auth` and `profile` are a bidirectional module-level pair — in
practice one unit. Neither can be enabled without the other.** Importing `auth.services` pulls in
`profile`, and importing `profile.routes` pulls in `auth`, so listing only one of them in
`[tool.splent] features` fails at startup. On top of that, because `auth` supplies the Flask-Login
setup, any product with a `@login_required` view anywhere needs `auth` loaded.

## Templates and assets

The feature renders two templates, both extending `base_template.html`:

```
app/features/auth/templates/auth/
├── login_form.html
└── signup_form.html
```

Its single script lives at `app/features/auth/assets/js/scripts.js` and is declared in
`init_feature` via the framework asset registry:

```python
register_asset("js", "auth.assets", subfolder="js", filename="scripts.js")
```

The base layout picks registered assets up, and the file is served by the blueprint's own
`auth.assets` route.

## Tests

One file per level of the pyramid, each declaring its marker at module level
(`pytestmark = pytest.mark.<level>`):

```
app/features/auth/tests/
├── test_unit.py           # unit: password hashing logic, no app, no DB
├── test_repository.py     # repository
├── test_service.py        # service: email availability, create_with_profile persistence
├── test_integration.py    # integration: signup-then-login round trip over the test client
├── test_selenium.py       # e2e: logs in with the seeded user1@example.com in a real browser
└── locustfile.py          # load: anonymous login/signup traffic against the seeded account
```

The `test_app` and `test_client` fixtures come from `splent_framework.fixtures.fixtures`,
re-exported by the root `conftest.py`. Run a level at a time with `rosemary test auth --unit`,
`--service`, `--integration` or `--e2e` (the last one needs the Selenium grid).

## Configuration

The feature reads no environment variables of its own (`os.getenv` does not appear anywhere in
`app/features/auth/`). The only indirect setting is `UPLOADS_DIR`: `temp_folder_by_user` builds its
path from the framework's `uploads_folder_name()`, which reads `UPLOADS_DIR` and defaults to
`uploads`.
