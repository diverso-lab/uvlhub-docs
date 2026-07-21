---
layout: default
title: hubfile
parent: Features
permalink: /features/hubfile
nav_order: 6
---

# hubfile
{: .no_toc }

The `hubfile` feature owns the individual stored file: the `file` table that maps a database row to
a UVL file on disk, the public endpoints to download and view one file, and the per-file view and
download metrics. Where [dataset]({{site.baseurl}}/features/dataset) serves the whole dataset as one
zip, `hubfile` serves one file at a time — it is what the file-level buttons on the dataset detail
page call. It lives in `app/features/hubfile/`.

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

## What it does

Every UVL file in a dataset is one `Hubfile` row: name, MD5 checksum, size, and the feature model it
belongs to. The rows are created during dataset upload (by `DataSetService.create_from_form`) and by
the dataset seeder; this feature's job is to locate the file on disk afterwards and serve it. The
path is derived, not stored: `HubfileService.get_path_by_hubfile` walks the joins up to the owning
dataset and user and resolves `<WORKING_DIR>/uploads/user_<id>/dataset_<id>/<name>`.

Both endpoints record metrics deduplicated by cookie, mirroring the dataset-level records: one
`HubfileDownloadRecord` or `HubfileViewRecord` per `(user or anonymous, file, cookie)` tuple.

## Routes

Real output of `rosemary route:list` for this blueprint:

```
Endpoint                Methods   Route
hubfile.assets          GET       /hubfile/<subfolder>/<filename>
hubfile.download_file   GET       /file/download/<int:file_id>
hubfile.view_file       GET       /file/view/<int:file_id>
```

Both file routes are public — no login required, matching the public DOI landing page that links to
them.

`/file/download/<id>` serves the file as an attachment. The download record is written only after
the file response has been built, so a request for a missing file 404s without ever counting as a
download. The `file_download_cookie` used for deduplication is set with a two-year `max_age`
(`60 * 60 * 24 * 365 * 2` seconds), so repeat downloads from the same browser stay collapsed into
one record across sessions:

```
curl -s -D - -o /dev/null http://localhost/file/download/1 | grep -i set-cookie
Set-Cookie: file_download_cookie=...; Expires=...; Max-Age=63072000; Path=/
```

`/file/view/<id>` returns the file's UVL source as JSON (`{"success": true, "content": "..."}`);
the dataset page fetches it to fill the file preview modal. A file whose row exists but whose file
is missing on disk answers a JSON 404 instead of crashing. Views are deduplicated through a
`view_cookie`, also set with the two-year `max_age` when absent.

## Models

`app/features/hubfile/models.py` defines:

| Model | Table | Purpose |
|:------|:------|:--------|
| `Hubfile` | `file` | Name, checksum, size, FK `feature_model_id` into featuremodel's `feature_model` (not nullable). |
| `HubfileViewRecord` | `file_view_record` | One view: nullable FK `user_id` into auth's `user`, FK `file_id`, date, cookie. |
| `HubfileDownloadRecord` | `file_download_record` | One download, same shape. |

`Hubfile` has no `user_id` or `dataset_id` column — ownership is resolved through the
`file → feature_model → data_set → user` join chain, which is what
`get_owner_user()` and `get_dataset()` do via `HubfileService`.

{: .note }
`Hubfile.get_formatted_size()` lazily imports `SizeService` from `dataset.services` inside the
method body — a model importing another feature's *service*. This is the clearest layer violation
in the codebase, and it means even hubfile's model layer cannot function without `dataset` present.

## Services and repositories

`app/features/hubfile/services.py`:

| Service | Purpose |
|:--------|:--------|
| `HubfileService` | `get_path_by_hubfile` (resolves the on-disk path under `WORKING_DIR`), `directory_for` (for `send_from_directory`), `read_text` (returns `None` when the file is missing), owner/dataset lookups, and the view/download totals. |
| `HubfileDownloadRecordService` | `record_download`, deduplicated per `(user, file, cookie)`. |
| `HubfileViewRecordService` | `record_view`, same pattern. |

`app/features/hubfile/repositories.py` holds `HubfileRepository` — whose owner and dataset lookups
join `User → DataSet → FeatureModel → Hubfile` — plus the two record repositories. The totals
(`total_hubfile_views`, `total_hubfile_downloads`) are computed in SQL with `func.count`, not by
loading rows into Python. These totals are also what `featuremodel` reports as feature model views
and downloads.

`HubfileSeeder` in `seeders.py` is an empty scaffold; sample files are seeded by dataset's
`DataSetSeeder`.

## Dependencies

Measured over production code only (tests excluded), `hubfile` imports three other features:

| Imports | Where | Why |
|:--------|:------|:----|
| `auth.models` | `models.py`, `services.py`, `repositories.py` | `User` for the owner lookup join and type hints; the record tables FK auth's `user`. |
| `dataset.models` | `models.py`, `services.py`, `repositories.py` | `DataSet` for the owner/dataset join chain and type hints. |
| `dataset.services` | `models.py`, lazily | `SizeService` inside `Hubfile.get_formatted_size` — a model importing another feature's service, the clearest layer violation in the codebase. |
| `featuremodel.models` | `repositories.py` | `FeatureModel` is the middle hop of the join chain. |

Fan-in — three features import `hubfile`:

| Imported by | For |
|:------------|:----|
| `dataset` | `DataSetService` creates `Hubfile` rows through `HubfileRepository` (skipping this feature's service); the seeder creates `Hubfile` rows; `view_dataset.html` links `url_for('hubfile.download_file', ...)` and its JavaScript fetches `/file/view/<id>` and `/file/download/<id>`. |
| `featuremodel` | `FeatureModelService` delegates its view/download totals to `HubfileService`; `FeatureModel.files` targets `Hubfile`. |
| `flamapy` | `FlamapyService` uses `HubfileService` to locate the UVL file to validate or convert. |

Taken together: [dataset]({{site.baseurl}}/features/dataset),
[featuremodel]({{site.baseurl}}/features/featuremodel) and `hubfile` form a module-level dependency
triangle — each of the three imports the other two. Together with `auth` they are the product's
core, and they are only meaningfully deployable as a unit.

## Templates and assets

```
app/features/hubfile/
├── templates/hubfile/index.html   # empty content block, not wired to any route
└── assets/js/scripts.js           # placeholder console.log
```

The feature has no `index` route, so `index.html` is scaffolding that nothing renders. The UI that
exercises hubfile — the view modal and the per-file download and conversion buttons — lives in
dataset's `view_dataset.html`.

## Tests

One file per layer, marker set at module level:

```
app/features/hubfile/tests/
├── test_unit.py          # pytest.mark.unit
├── test_repository.py    # pytest.mark.repository
├── test_service.py       # pytest.mark.service
├── test_integration.py   # pytest.mark.integration
└── locustfile.py         # load tests
```

There is no `test_selenium.py`: the browser-level coverage of file viewing and downloading lives in
the dataset and featuremodel e2e suites, which drive the dataset detail page. The layers here cover
size formatting, the owner/dataset join chain, cookie-deduplicated view and download records, the
JSON 404 for a file missing on disk, and the attachment download. Run one layer at a time:

```
rosemary test hubfile --unit
rosemary test hubfile --integration
```

## Configuration

`grep os.getenv` over the feature's production code finds one variable:

| Variable | Read in | Used for |
|:---------|:--------|:---------|
| `WORKING_DIR` | `services.py` | Root under which `uploads/user_<id>/dataset_<id>/<name>` is resolved by `get_path_by_hubfile`. |

The feature ships no `.env.example` of its own; `WORKING_DIR` comes from the root `.env` and must
match the value the `dataset` feature used when it moved the files into `uploads/`.
