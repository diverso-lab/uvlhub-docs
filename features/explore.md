---
layout: default
title: explore
parent: Features
permalink: /features/explore
nav_order: 3
---

# explore
{: .no_toc }

The `explore` feature is the search engine of uvlhub. It serves the `/explore` page, registers the
`Explore` entry in the navigation bar, and answers search queries over every synchronized dataset in
the hub. It lives in `app/features/explore`.

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

## What it does

`GET /explore` renders a search page with a free-text query box, a publication type select and a
sorting radio group. The page itself contains no results: the feature's JavaScript posts the current
filter values as JSON to `POST /explore` and paints the returned dataset cards client-side. Every
keystroke and every filter change triggers a new search.

The repository builds one query for all of it. The free text is normalized first (accents removed
via `unidecode`, punctuation stripped, lowercased), then split into words, and each word is matched
with `ilike` against eleven columns: dataset title, description and tags, author name, affiliation
and ORCID, and feature model filename, title, description, publication DOI and tags. All those
conditions are combined with `OR`, so a dataset matches when any word appears in any of those
places.

Two hard constraints always apply: only datasets whose `dataset_doi` is not `NULL` (that is,
datasets already synchronized with Zenodo) and that have at least one feature model can ever appear
in the results.

On top of the free text, three optional filters are accepted in the JSON body:

| Field | Default | Effect |
|:------|:--------|:-------|
| `query` | `""` | Free text, word-by-word `OR` match as described above. |
| `publication_type` | `"any"` | Exact match against the `PublicationType` enum. Unknown values are ignored. |
| `tags` | `[]` | `OR` of `ilike` matches against the dataset tags column. |
| `sorting` | `"newest"` | `"newest"` or `"oldest"`, ordering by `created_at`. |

A `POST /explore` with no JSON body at all is valid and behaves like an empty query: it returns the
full unfiltered list of synchronized datasets, newest first. You can verify it from the command
line:

```
curl -X POST http://localhost/explore
```

which answers a JSON array of dataset objects (`title`, `description`, `authors`, `tags`,
`publication_type`, `url`, download link and sizes), produced by `DataSet.to_dict()`.

Two behaviours of the client are worth knowing:

- **Requests are sequenced.** Each new search aborts the in-flight one with an `AbortController`
  before firing, so a slow broad query can no longer come back late and overwrite the results of a
  narrower one. Aborted requests are treated as superseded queries, not as errors.
- **`?query=` prefills the search.** Opening `/explore?query=tag1` fills the search box and runs the
  search immediately. The landing page and the dataset cards use this to link into filtered views.

{: .note }
The search form itself never sends the `tags` field; it is available to API clients posting JSON
directly. The tag badges on each result card reuse the free-text box instead: clicking one copies
the tag into `query` and re-runs the search, which matches tags because the free text is also
matched against both tags columns.

## Routes

| Endpoint | Method | Rule | Purpose |
|:---------|:-------|:-----|:--------|
| `explore.index` | GET | `/explore` | Renders the search page. Accepts `?query=` to prefill the search box. |
| `explore.search` | POST | `/explore` | Runs a search. JSON body with the filters above, JSON array out. |
| `explore.assets` | GET | `/explore/<subfolder>/<filename>` | Serves the feature's static assets (registered by the framework asset registry). |

## Models

The feature defines **no models**, and that is part of its design: explore is a pure read-side
consumer. It queries the models that `dataset` and `featuremodel` own (`DataSet`, `DSMetaData`,
`Author`, `FeatureModel`, `FMMetaData`) and never writes to any of them. There are no migrations
and no seeder to run for this feature.

## Services and repositories

| Class | File | Role |
|:------|:-----|:-----|
| `ExploreService` | `services.py` | Thin `BaseService` subclass. Its only method, `filter(query, sorting, publication_type, tags, **kwargs)`, forwards to the repository. |
| `ExploreRepository` | `repositories.py` | `BaseRepository` over `DataSet`. Builds the whole search query: normalization, the `OR` filter list, the DOI and feature model constraints, the publication type and tags filters, and the ordering. |
| `ExploreForm` | `forms.py` | A `FlaskForm` with a single submit field. Its real job is rendering the CSRF token the page's JavaScript sends back with each search. |

## Dependencies

Measured over production imports (tests excluded):

- **explore imports** `app.features.dataset.models` and `app.features.featuremodel.models`, both
  used exclusively for read-only query building inside `ExploreRepository`.
- **Nothing imports explore.** No Python module and no template of any other feature references it.

The verdict is that explore is a clean read-side consumer: disabling the feature removes the search
page and its navigation entry, and breaks nothing else in the application.

Third-party packages specific to this feature: `Unidecode` (query normalization). Everything else
is the shared Flask/SQLAlchemy stack.

## Templates and assets

```
app/features/explore/
├── templates/explore/index.html
└── assets/js/scripts.js
```

`index.html` extends `base_template.html` and renders the filter column (query box, publication
type select, sorting radios, clear-filters button) plus the empty containers the JavaScript fills:
the results list, the results counter and a "not found" panel.

`scripts.js` is declared in `init_feature` through the framework asset registry
(`register_asset("js", "explore.assets", ...)`), which means it is served on **every** page of the
application, not only on `/explore`. The whole file is therefore guarded: each entry point first
checks that the `#filters` form exists and returns immediately anywhere else. The script wires the
filter inputs (both `input` and `change` events, collapsed into one repaint by the abort guard),
renders the result cards, formats dates, implements the clickable tag and publication type badges,
and the clear-filters reset.

The navigation entry is registered in `__init__.py`:

```python
register_nav_item("explore", "Explore", "/explore", order=20, icon="search")
```

## Tests

One file per layer, each declaring its marker at module level (`pytestmark`):

```
app/features/explore/tests/
├── test_repository.py    # pytest.mark.repository  (13 tests)
├── test_service.py       # pytest.mark.service      (5 tests)
├── test_integration.py   # pytest.mark.integration  (6 tests)
├── test_selenium.py      # pytest.mark.e2e          (9 tests)
└── locustfile.py         # load testing
```

The repository layer carries the interesting cases: blank and whitespace-only queries, accent and
punctuation normalization, word-by-word `OR` semantics, tags filtering (alone and combined with the
query), unknown publication types being ignored, and the guarantee that datasets without a DOI or
without a feature model are never returned. The integration layer covers the HTTP contract,
including the empty-payload and missing-body searches, and the Selenium layer drives the real page:
typing queries, the not-found panel, clearing filters and the `?query=` URL parameter.

Run one layer at a time:

```
rosemary test explore --repository
rosemary test explore --service
rosemary test explore --integration
rosemary test explore --e2e
```

The e2e layer needs the Selenium grid from the Docker development stack. The `locustfile.py` drives
`POST /explore` under load and runs through `rosemary locust explore`.

## Configuration

None. The feature reads no environment variables and ships no `.env.example`. Its only
initialization is in `init_feature`: registering its script with the asset registry and its
navigation item with the nav registry.
