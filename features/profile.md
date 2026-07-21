---
layout: default
parent: Features
title: profile
permalink: /features/profile
nav_order: 7
---

# profile
{: .no_toc }

The `profile` feature owns the `UserProfile` model — the person behind a `User` account: name,
surname, optional ORCID and optional affiliation — and the two pages a signed-in user gets about
themselves. `/profile/summary` shows the profile card (name, surname, affiliation, ORCID, email)
together with a paginated table of the user's own datasets, five per page, newest first, with a
total count. Each dataset title links to its DOI page when it has been synchronized to Zenodo, or to
the unsynchronized dataset view when it has not.

`/profile/edit` is the edit form. It is built with `UserProfileForm(obj=profile)`, which does two
things at once: on GET it prefills every field from the stored profile, and on POST WTForms
backfills any field absent from the submitted data with the stored value, so a partial edit
preserves untouched fields instead of blanking them. This prefill-and-preserve behaviour was
recently fixed and is pinned down by dedicated integration and e2e tests. Validation enforces the
19-character `0000-0000-0000-0000` ORCID format and a 5 to 100 character affiliation, both optional;
name and surname are required. A successful save flashes "Profile updated successfully" and
redirects back to the form.

Profiles are never created here. Creation happens in `auth` — signup and the seeder build the
`UserProfile` row together with the `User` — which is one half of the tight coupling described
below.

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

## Routes

From `rosemary route:list` on the running stack:

| Endpoint | Methods | Rule |
|:---------|:--------|:-----|
| `profile.edit_profile` | GET, POST | `/profile/edit` |
| `profile.my_profile` | GET | `/profile/summary` |
| `profile.assets` | GET | `/profile/<subfolder>/<filename>` |

Both pages are `@login_required`; anonymous visitors are redirected to `/login` by the login manager
that `auth` configures. `my_profile` reads the page number from the `page` query parameter
(`/profile/summary?page=2`). `profile.assets` is the per-feature static route every `BaseBlueprint`
gets.

## Models

`app/features/profile/models.py` defines one model, `UserProfile`:

| Column | Type | Notes |
|:-------|:-----|:------|
| `id` | Integer | Primary key. |
| `user_id` | Integer | Foreign key to `user.id`, unique and not null — a strict one-to-one with auth's `User`. |
| `name` | String(100) | Not null. |
| `surname` | String(100) | Not null. |
| `orcid` | String(19) | Optional, `0000-0000-0000-0000` format enforced by the form. |
| `affiliation` | String(100) | Optional. |

The reverse side lives in `auth`: `User.profile` is the one-to-one relationship (`uselist=False`)
with a `user` backref, which is how routes reach the profile as `current_user.profile`.

## Services and repositories

`UserProfileService` extends `BaseService` over a `UserProfileRepository`:

| Method | Purpose |
|:-------|:--------|
| `update_profile(user_profile_id, form)` | Validates the form and applies every field except the non-model ones (`submit`, `csrf_token`) through the base `update`. Returns `(instance, None)` on success or `(None, form.errors)` on validation failure. |
| `summary_for_user(user_id, page, per_page=5)` | Builds the summary page payload: the page of the user's datasets, the pagination object and the total dataset count. |

`UserProfileRepository` is a plain `BaseRepository` subclass with no extra queries. The dataset data
for the summary comes from `dataset`'s `DataSetRepository` (`paginate_for_user`, `count_for_user`),
which the service holds directly — see Dependencies.

## Dependencies

Measured from the production code (imports, tests excluded):

| Edge | Where | What it means |
|:-----|:------|:--------------|
| `profile` → `auth.services` | `routes.py` | `edit_profile` asks `AuthenticationService` for the authenticated user's profile. |
| `profile` → `dataset.repositories` | `services.py` | `summary_for_user` paginates and counts the user's datasets through `DataSetRepository` — a cross-feature service-to-repository reach that bypasses dataset's own service layer. |

Inbound, `auth` imports from `profile` at module level in three places: `profile.models` (in
`services.py` and `seeders.py`), `profile.repositories` (in `services.py`) and `profile.services`
(in `routes.py`). At the schema level, `user_profile.user_id` is a foreign key to auth's `user`
table.

The practical consequence: **`auth` and `profile` are a bidirectional module-level pair — in
practice one unit. Neither can be enabled without the other.** Importing `profile.routes` pulls in
`auth`, and importing `auth.services` or `auth.routes` pulls in `profile`, so listing only one of
them in `[tool.splent] features` fails at startup. The `dataset.repositories` import means `profile`
cannot be loaded in isolation from `dataset` either: importing `profile.services` pulls it in, and
the summary page has nothing to paginate without it.

## Templates and assets

The feature renders two templates, both extending `base_template.html`:

```
app/features/profile/templates/profile/
├── edit.html      # the form, with flashed success/error alerts and per-field errors
└── summary.html   # profile card, dataset table, Bootstrap pagination controls
```

`summary.html` renders the pagination with `pagination.iter_pages()`, disabling the previous/next
arrows at the edges, and switches each dataset link between the DOI URL and the unsynchronized
dataset view. `edit.html` additionally falls back to `current_user.profile` values when a field has
no form data, reinforcing the prefill behaviour at the template level.

Its single script lives at `app/features/profile/assets/js/scripts.js` and is declared in
`init_feature` via the framework asset registry:

```python
register_asset("js", "profile.assets", subfolder="js", filename="scripts.js")
```

The base layout picks registered assets up, and the file is served by the blueprint's own
`profile.assets` route.

## Tests

One file per level of the pyramid, each declaring its marker at module level
(`pytestmark = pytest.mark.<level>`):

```
app/features/profile/tests/
├── test_unit.py           # unit: update_profile field filtering, summary payload assembly
├── test_repository.py     # repository
├── test_service.py        # service: pagination (newest first, per-page, isolation between users), ORCID rejection
├── test_integration.py    # integration: login requirement, prefill, partial-post preservation, invalid ORCID re-render
├── test_selenium.py       # e2e: summary contents per seeded user, prefill and preservation in a real browser
└── locustfile.py          # load
```

The integration file is where the prefill-and-preserve contract is enforced:
`test_edit_form_is_prefilled_with_stored_profile` and
`test_edit_partial_post_preserves_fields_left_out_of_the_form` fail if either half regresses. The
`test_app` and `test_client` fixtures come from `splent_framework.fixtures.fixtures`, re-exported by
the root `conftest.py`; the e2e tests sign in as the users seeded by `auth` (`user1@example.com` /
`1234`). Run a level at a time with `rosemary test profile --unit`, `--service`, `--integration` or
`--e2e` (the last one needs the Selenium grid).

## Configuration

None. The feature reads no environment variables (`os.getenv` does not appear anywhere in
`app/features/profile/`) and ships no `.env.example`.
