---
layout: default
title: public
parent: Features
permalink: /features/public
nav_order: 8
---

# public
{: .no_toc }

The `public` feature is uvlhub's landing page. It serves `/`, registers the `Home` entry in the
navigation bar, and renders the latest synchronized datasets together with the hub-wide statistics.
It lives in `app/features/public`.

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

## What it does

A single route, `GET /`, renders `public/index.html` with:

- **The latest synchronized datasets** (`DataSetService.latest_synchronized()`), each shown as a
  card with title, publication type, authors, uvlhub DOI (with a copy-to-clipboard icon), tags,
  and view/download buttons, followed by an "Explore more datasets" link into `/explore`.
- **Hub statistics**, six independent counters:

| Counter | Backing service call |
|:--------|:---------------------|
| datasets | `DataSetService.count_synchronized_datasets()` |
| feature models | `FeatureModelService.count_feature_models()` |
| datasets viewed | `DataSetService.total_dataset_views()` |
| feature models viewed | `FeatureModelService.total_feature_model_views()` |
| datasets downloaded | `DataSetService.total_dataset_downloads()` |
| feature models downloaded | `FeatureModelService.total_feature_model_downloads()` |

- **The related publication** (the UVLHub JSS paper) with copy-in-BibTex and copy-in-RIS buttons.
- **A welcome card** inviting anonymous visitors to sign up; it disappears once the visitor is
  logged in.

The page is fully public: no login is required, and it renders correctly on an empty database
(all counters at zero, no cards). It also tolerates datasets whose tags are `NULL` — the template
guards the tag loop with {% raw %}`{% if dataset.ds_meta_data.tags %}`{% endraw %} before
splitting, so a synchronized dataset without tags renders without error. Both behaviours are
covered by tests.

## Routes

| Endpoint | Method | Rule | Purpose |
|:---------|:-------|:-----|:--------|
| `public.index` | GET | `/` | Renders the landing page. |
| `public.assets` | GET | `/public/<subfolder>/<filename>` | Serves the feature's static assets (asset registry). |

## Models

The feature defines **no models**, and that is part of its design: public is a presentation-only
feature. Everything it shows belongs to `dataset` and `featuremodel`; public just asks their
services and renders the answers. There are no migrations, no repository and no seeder.

## Services and repositories

None of its own — `routes.py` is the entire Python surface. It instantiates `DataSetService` and
`FeatureModelService` and calls the seven methods listed above. There is no `services.py`,
`repositories.py` or `forms.py` in this feature.

## Dependencies

Measured over production imports (tests excluded):

- **public imports** `app.features.dataset.services` and `app.features.featuremodel.services` —
  services only, never another feature's models or repositories.
- **Nothing imports public.**

This makes public the cleanest consumer in the codebase and the exemplary pattern for cross-feature
dependencies: when a feature needs another feature's data, it should go through that feature's
service layer exactly like this, leaving the owning feature free to change its models and queries
without breaking anyone.

Beyond that, public owns two global touches registered in `init_feature`: the `Home` navigation
item and, through its template, the landing statistics:

```python
register_nav_item("home", "Home", "/", order=10, icon="home")
```

No third-party packages are specific to this feature.

## Templates and assets

```
app/features/public/
├── templates/public/index.html
└── assets/js/scripts.js
```

`index.html` extends `base_template.html` and contains the whole landing page described above. The
copy-to-clipboard buttons rely on the global `copyText` helper from the base layout, and the icons
are Feather icons.

`scripts.js` is declared with the asset registry in `init_feature` (every feature registers its
script via `register_asset`) and is served on every page; its current content is a single
`console.log` line, a placeholder proving the wiring works.

## Tests

```
app/features/public/tests/
├── test_service.py       # pytest.mark.service      (3 tests)
├── test_integration.py   # pytest.mark.integration  (5 tests)
├── test_selenium.py      # pytest.mark.e2e          (6 tests)
└── locustfile.py         # load testing
```

There is no unit or repository file: the feature has no logic of its own below the HTTP layer. The
service tests pin down the statistics the page depends on (zero on an empty database, counters
reflecting persisted rows, `latest_synchronized` returning the five newest synchronized datasets).
The integration tests render the page on an empty database, check the statistics block, verify that
only synchronized datasets are listed, that a synchronized dataset without tags renders, and that
anonymous visitors can load the page. The Selenium tests drive the real landing page: seeded
counts, every statistic, DOI links, the sign-up card appearing for anonymous visitors and
disappearing after login, and the "Explore more datasets" button.

```
rosemary test public --service
rosemary test public --integration
rosemary test public --e2e
```

The e2e layer needs the Selenium grid from the Docker development stack. `locustfile.py` loads
`GET /` — a single task, but the heaviest page of the application, since rendering it aggregates
the latest datasets plus six independent counters — and runs through `rosemary locust public`.

## Configuration

None. The feature reads no environment variables and ships no `.env.example`. Its only
initialization is in `init_feature`: registering its script with the asset registry and the `Home`
item with the nav registry.
