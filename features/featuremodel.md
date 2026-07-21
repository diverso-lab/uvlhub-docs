---
layout: default
title: featuremodel
parent: Features
permalink: /features/featuremodel
nav_order: 4
---

# featuremodel
{: .no_toc }

The `featuremodel` feature owns the domain models that tie a dataset to its UVL files:
`FeatureModel`, its metadata (`FMMetaData`) and its metrics (`FMMetrics`). It has almost no UI of its
own — a single mostly-empty page at `/featuremodel` — because feature models are rendered where they
matter, on the dataset detail page. What it contributes at runtime is the schema in the middle of the
`dataset` → `featuremodel` → `hubfile` chain and the counters the public landing page shows. It
lives in `app/features/featuremodel/`.

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

## What it does

Every UVL file uploaded to uvlhub becomes one `FeatureModel` row inside a dataset, pointing at its
`FMMetaData` (filename, title, description, publication type, tags, UVL version, authors) and at its
stored files in [hubfile]({{site.baseurl}}/features/hubfile). The rows are created by
`DataSetService.create_from_form` during a dataset upload — this feature defines the tables and the
services around them; the writing is driven from [dataset]({{site.baseurl}}/features/dataset).

`FeatureModelService` also feeds the statistics on the landing page: the number of feature models
(counted in SQL with `COUNT`), and total feature model views and downloads, which it defines as the
hubfile view and download totals and therefore delegates to `HubfileService`.

## Routes

Real output of `rosemary route:list` for this blueprint:

```
Endpoint              Methods   Route
featuremodel.assets   GET       /featuremodel/<subfolder>/<filename>
featuremodel.index    GET       /featuremodel
```

`/featuremodel` is public, accepts only GET and renders `featuremodel/index.html`, a template whose
content block is empty — the page exists as scaffolding, not as a destination. The real UI for
feature models is the dataset detail page at `/doi/<doi>/`, which lists each model with its view,
download and flamapy conversion actions.

## Models

`app/features/featuremodel/models.py` defines:

| Model | Table | Purpose |
|:------|:------|:--------|
| `FeatureModel` | `feature_model` | One UVL model. FK `data_set_id` into dataset's `data_set` (not nullable), FK `fm_meta_data_id`. `files` relationship to hubfile's `Hubfile`. |
| `FMMetaData` | `fm_meta_data` | `uvl_filename`, title, description, `publication_type`, DOI, tags, `uvl_version`, FK to `FMMetrics`. |
| `FMMetrics` | `fm_metrics` | `solver` / `not_solver` text columns. |

The module imports `Author` and `PublicationType` from `dataset.models` at module level:
`FMMetaData.authors` is a relationship over dataset's `author` table (via its `fm_meta_data_id`
column), and the publication type column reuses dataset's enum. The schema tie is therefore
bidirectional — `feature_model` has a foreign key into dataset's `data_set`, and dataset's `author`
table has a foreign key into `fm_meta_data`. Neither feature's tables can exist without the other.

## Services and repositories

`app/features/featuremodel/services.py`:

| Service | Purpose |
|:--------|:--------|
| `FeatureModelService` | `count_feature_models` (SQL `COUNT`), `total_feature_model_views` and `total_feature_model_downloads`, both delegated to `HubfileService`. |
| `FMMetaDataService` | Thin CRUD wrapper over `FMMetaDataRepository`. |

`app/features/featuremodel/repositories.py` holds `FeatureModelRepository` (whose
`count_feature_models` uses `func.count` so the database does the counting) and
`FMMetaDataRepository`, both extending `BaseRepository`.

`FeaturemodelSeeder` in `seeders.py` is an empty scaffold; the sample feature models are seeded by
dataset's `DataSetSeeder`.

## Dependencies

Measured over production code only (tests excluded), `featuremodel` imports two other features:

| Imports | Where | Why |
|:--------|:------|:----|
| `dataset.models` | `models.py`, module level | `Author` and `PublicationType`. This is a schema-level tie: featuremodel's metadata is built out of dataset's tables and enums, so the coupling exists before any request is served. |
| `hubfile.services` | `services.py` | Feature model view/download totals are defined as hubfile view/download totals. |

Fan-in — five features import `featuremodel`:

| Imported by | For |
|:------------|:----|
| `dataset` | `DataSetService` uses `FeatureModelRepository`/`FMMetaDataRepository` directly (skipping this feature's service); the seeder creates `FeatureModel` and `FMMetaData` rows. |
| `explore` | Search joins over `FeatureModel` and `FMMetaData`. |
| `hubfile` | `HubfileRepository` joins through `FeatureModel` to find a file's dataset and owner. |
| `public` | The landing page reads the counters from `FeatureModelService`. |
| `zenodo` | `upload_file` takes a `FeatureModel` to know which UVL file to push. |

Taken together: [dataset]({{site.baseurl}}/features/dataset), `featuremodel` and
[hubfile]({{site.baseurl}}/features/hubfile) form a module-level dependency triangle — each of the
three imports the other two. Together with `auth` they are the product's core, and they are only
meaningfully deployable as a unit.

## Templates and assets

```
app/features/featuremodel/
├── templates/featuremodel/index.html   # empty content block
└── assets/js/scripts.js                # placeholder console.log
```

`init_feature` registers `scripts.js` with the framework asset registry, but the script is a
one-line placeholder. The templates that actually display feature models belong to `dataset`
(`view_dataset.html`).

## Tests

One file per layer, marker set at module level:

```
app/features/featuremodel/tests/
├── test_unit.py          # pytest.mark.unit
├── test_repository.py    # pytest.mark.repository
├── test_service.py       # pytest.mark.service
├── test_integration.py   # pytest.mark.integration
└── test_selenium.py      # pytest.mark.e2e
```

The unit and repository layers cover the models and the SQL counting; the service layer checks that
view and download totals really aggregate hubfile records; integration checks `/featuremodel` is
public, renders its own template and rejects POST. Because the feature's real UI lives on the
dataset page, the e2e file drives `/doi/<doi>/` and asserts that every feature model of the dataset
is listed, scoped correctly, and offers its UVL and converted exports. Run one layer at a time:

```
rosemary test featuremodel --unit
rosemary test featuremodel --integration
rosemary test featuremodel --e2e
```

## Configuration

`grep os.getenv` over the feature's production code finds nothing: `featuremodel` reads no
environment variables and ships no `.env.example`. Everything it needs at runtime comes through the
database and the features around it.
