---
layout: default
title: flamapy
parent: Features
permalink: /features/flamapy
nav_order: 5
---

# flamapy
{: .no_toc }

The `flamapy` feature wraps the [Flamapy](https://flamapy.github.io/) feature model tooling behind
HTTP endpoints. It validates the UVL files stored in the hub and converts them to other feature
model formats (Glencoe, SPLOT, DIMACS CNF). It lives in `app/features/flamapy` and has no page of
its own: its endpoints are consumed by the dataset detail page.

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

## What it does

Every endpoint takes the id of a *hubfile* (a stored UVL file) and operates on the file on disk.

**Validation.** `GET /flamapy/check_uvl/<file_id>` parses the file with the ANTLR-generated UVL
lexer and parser (`uvlparser` package) and collects every syntax error through a custom
`ErrorListener`. It genuinely validates:

```
curl http://localhost/flamapy/check_uvl/1
{"message": "Valid Model"}                                # 200
```

For a malformed model it answers `400` with the collected error list:

```json
{"errors": ["The UVL has the following error that prevents reading it: Line 4:8 - ..."]}
```

Messages containing a tab hint are classified as warnings instead of errors, mirroring the UVL
parser's tab-related diagnostics.

`GET /flamapy/valid/<file_id>` is the existence-aware variant: it answers `404` with a JSON error
for an unknown id, and otherwise `{"success": true|false, "file_id": <id>}` with a `200`, running
the same real validation.

{: .warning }
`check_uvl` does **not** check that the hubfile exists first: for an unknown id it answers a JSON
`500` (`{"error": "..."}`), not a `404`. Use `/flamapy/valid/<file_id>` when the id may not exist.

**Export.** Three routes convert a UVL model and stream the result as a download attachment:

```
curl -OJ http://localhost/flamapy/to_glencoe/1     # <name>_glencoe.txt
curl -OJ http://localhost/flamapy/to_splot/1       # <name>_splot.txt
curl -OJ http://localhost/flamapy/to_cnf/1         # <name>_cnf.txt
```

The conversion writes to a temporary file, `send_file` streams it, and an `after_this_request` hook
deletes the temporary file once the response has been sent. Error cases return JSON instead of
tracebacks: an unknown id answers `404 {"error": "No hubfile with id N"}` and a hubfile whose UVL
is missing from disk answers `500 {"error": "The UVL file is missing from disk"}`.

## Routes

| Endpoint | Method | Rule | Purpose |
|:---------|:-------|:-----|:--------|
| `flamapy.check_uvl` | GET | `/flamapy/check_uvl/<int:file_id>` | Syntax validation. `200` valid, `400` with error list, `500` JSON error otherwise. |
| `flamapy.valid` | GET | `/flamapy/valid/<int:file_id>` | Validation with existence check. `404` for unknown ids, else `{"success": bool}`. |
| `flamapy.to_glencoe` | GET | `/flamapy/to_glencoe/<int:file_id>` | Download the model in Glencoe JSON format. |
| `flamapy.to_splot` | GET | `/flamapy/to_splot/<int:file_id>` | Download the model in SPLOT format. |
| `flamapy.to_cnf` | GET | `/flamapy/to_cnf/<int:file_id>` | Download the model as DIMACS CNF (via a PySAT transformation). |
| `flamapy.assets` | GET | `/flamapy/<subfolder>/<filename>` | Serves the feature's static assets (asset registry). |

## Models

The feature defines **no models**, and that is part of its design: flamapy is purely behavioural.
It reads a hubfile, parses or converts it, and returns the bytes; it persists nothing. Consequently
there is no repository layer, no migrations, and its `seeders.py` seeds an empty list.

## Services and repositories

Everything lives in `FlamapyService` (`services.py`). Deliberately, it is **not** a `BaseService`
subclass: `BaseService` exists to wrap a repository around a model, and this feature has neither.
It holds a `HubfileService` instance instead and exposes:

| Method | Purpose |
|:-------|:--------|
| `validate_uvl(file_id)` | Parses the UVL and returns the list of syntax errors; empty list means valid. |
| `hubfile_exists(file_id)` | `True` when a hubfile row with that id exists. Backs the `404` in `/flamapy/valid`. |
| `export(file_id, target)` | Converts to `"glencoe"`, `"splot"` or `"cnf"`. Returns `(tmp_path, download_name)`; the caller owns the temporary file. |
| `cleanup(path)` | Static, best-effort `os.remove`, used by the routes via `after_this_request`. |

Supporting pieces in the same file:

- `_UVLErrorListener` — an ANTLR `ErrorListener` that accumulates
  `Line <line>:<column> - <message>` strings and classifies tab-related messages as warnings.
- `_EXPORT_FORMATS` — a dispatch table mapping each target to its writer class, tempfile suffix and
  download-name suffix (`GlencoeWriter`/`.json`/`_glencoe.txt`, `SPLOTWriter`/`.splx`/`_splot.txt`,
  `DimacsWriter`/`.cnf`/`_cnf.txt`). The `"cnf"` target additionally runs `FmToPysat` before
  writing. Unknown targets raise `ValueError` before touching the database.

`forms.py` defines a `FlamapyForm` with a single submit field; no route uses it. It is scaffolding
from the feature template.

## Dependencies

Measured over production imports (tests excluded):

- **flamapy imports** `app.features.hubfile.services` only — proper service-layer use, never
  another feature's models or repositories.
- **Nothing imports flamapy at the Python level.** However, the dataset feature's detail template
  (`app/features/dataset/templates/dataset/view_dataset.html`) links into flamapy endpoints four
  times via {% raw %}`{{ url_for('flamapy.valid', ...) }}`, `{{ url_for('flamapy.to_glencoe', ...) }}`,
  `{{ url_for('flamapy.to_cnf', ...) }}` and `{{ url_for('flamapy.to_splot', ...) }}`{% endraw %},
  and its inline JavaScript fetches `/flamapy/check_uvl/<id>` for the "Check" button.

So the honest verdict is: **python-decoupled, UI-coupled**. Disabling flamapy breaks the dataset
detail page, because Jinja raises on `url_for` to an unregistered endpoint. The Python layers are
cleanly separated; the coupling lives entirely in dataset's templates.

Third-party packages specific to this feature (`requirements.txt`): `flamapy`, `flamapy-fm`,
`flamapy-sat`, `flamapy-bdd`, `flamapy-fw` (all 2.5.0), `uvlparser` (the `uvl` lexer/parser
modules) and `antlr4-python3-runtime`.

## Templates and assets

```
app/features/flamapy/
├── templates/flamapy/index.html
└── assets/js/scripts.js
```

Both are effectively empty. `index.html` extends the base template with an empty content block and
**no route renders it** — the feature has no index page. `scripts.js` is an empty file, but it is
still declared with the asset registry in `init_feature` (every feature registers its script via
`register_asset`), so the framework serves it on every page. Unlike `explore` and `public`, flamapy
registers no navigation item.

## Tests

```
app/features/flamapy/tests/
├── test_unit.py          # pytest.mark.unit         (8 tests)
├── test_service.py       # pytest.mark.service      (7 tests)
├── test_integration.py   # pytest.mark.integration (11 tests)
└── locustfile.py         # load testing
```

There is no repository layer and no page to drive, so there are no repository or Selenium files.
The unit layer covers the error listener (positions, tab-warning classification, accumulation
order), the export dispatch table and `cleanup`. The service layer parses real well-formed and
malformed UVL files and checks each writer's output (DIMACS clauses, Glencoe JSON tree, SPLOT
tree) and the download naming. The integration layer exercises the full HTTP contract shown above,
including the `400` error list, the `404`s and the JSON errors for missing files on disk.

```
rosemary test flamapy --unit
rosemary test flamapy --service
rosemary test flamapy --integration
```

## Configuration

None. The feature reads no environment variables and ships no `.env.example`. Its only
initialization is registering its (empty) script with the asset registry.
