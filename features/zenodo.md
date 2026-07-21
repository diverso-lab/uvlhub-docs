---
layout: default
title: Zenodo
parent: Features
permalink: /features/zenodo
nav_order: 1
---

# Zenodo
{: .no_toc }

Zenodo is an open access repository that allows researchers, scientists, academics and anyone interested in sharing their research to upload and store research data, publications, software and other scientific results. It was created by OpenAIRE and CERN (European Organization for Nuclear Research) to support the open access movement and facilitate the sharing and preservation of scientific data.

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

## Obtain a token

To use the Zenodo feature, it is important to obtain a token in Zenodo first.

{: .warning }
**We recommend creating the token in the Sandbox version of Zenodo ([https://sandbox.zenodo.org/](https://sandbox.zenodo.org/)), in order to generate fictitious DOIs 
and not make intensive use of the real Zenodo SLA.**

1. **Create an Account on Zenodo**
   - Go to [Zenodo](https://sandbox.zenodo.org/).
   - Click on `Sign up` and complete the registration.

2. **Log in to Zenodo**
   - Go to [Zenodo](https://sandbox.zenodo.org/).
   - Click on `Log in` and log in with your account.

3. **Access the Tokens Section**
   - Click on your username in the top right corner.
   - Select `Applications`.

4. **Create a New Access Token**
   - Under `Personal access tokens`, click on `New token`.
   - Assign a name for your token.
   - **Select all permissions** to grant full access.
     - Read: Allows read-only access.
     - Write: Allows creating and modifying records.
     - Delete: Allows deleting records.
   - Click `Create`.

5. **Save the Access Token**
   - Copy and save the generated token in a secure place.

## Generate `.env` file

To generate the Zenodo `.env` file in `app/features/zenodo`, run in root project:

```
cp app/features/zenodo/.env.example app/features/zenodo/.env
```

## Include your access token

In the generated `.env`file, you must include the access token obtained in Zenodo:

```
ZENODO_ACCESS_TOKEN=<GET_ACCESS_TOKEN_IN_ZENODO>
```

{: .important-title }
> A composition of variables is necessary!
>
> To perform the composition of all environment variables, refer to section [Composing environment]({{site.baseurl}}/rosemary/extending_uvlhub/composing_environment).

## Which Zenodo instance is used

`ZenodoService` picks the API URL from `FLASK_ENV`. In `development` (and in anything that is not
`production`) it targets the sandbox; in `production` it targets the real Zenodo:

| `FLASK_ENV` | Default API URL |
|:------------|:----------------|
| `development` | `https://sandbox.zenodo.org/api/deposit/depositions` |
| `production` | `https://zenodo.org/api/deposit/depositions` |

Setting `ZENODO_API_URL` in your `.env` overrides the default in either case.

## Verify the connection

Once the token is composed into the root `.env` and the app is running, hit the test endpoint. With the
Docker development stack, nginx publishes the app on port 80:

```
curl http://localhost/zenodo/test
```

With a manual installation, Flask serves it directly on port 5000:

```
curl http://localhost:5000/zenodo/test
```

It creates a throwaway deposition, uploads a small test file to it, deletes the deposition again and
returns JSON:

```json
{"success": true, "messages": []}
```

If `success` comes back `false`, read `messages`. It reports which step failed and the HTTP status
Zenodo answered with, which usually means the token is missing, wrong, or does not carry the write and
delete scopes. The most common failure is the very first step, creating the deposition:

```json
{"success": false, "messages": "Failed to create test deposition on Zenodo. Response code: 403"}
```

{: .warning }
`messages` changes type between the two cases. When the deposition cannot be created, the service
returns early and `messages` is a plain string. In every other case it is a list of per-step messages,
empty on success. Parse it defensively.

## What the feature does

`app/features/zenodo/services.py` wraps the Zenodo deposition REST API. `ZenodoService` extends
`BaseService` from `splent_framework` and exposes:

| Method | Purpose |
|:-------|:--------|
| `test_connection()` | `True` if the depositions endpoint answers 200 with your token. |
| `test_full_connection()` | Full create, upload and delete round trip. Backs `/zenodo/test`. |
| `get_all_depositions()` | Every deposition visible to the token. |
| `create_new_deposition(dataset)` | Creates a deposition from a `DataSet`'s metadata. |
| `upload_file(dataset, deposition_id, feature_model, user=None)` | Uploads one UVL file to a deposition. |
| `publish_deposition(deposition_id)` | Publishes the deposition, which mints the DOI. |
| `get_deposition(deposition_id)` | Fetches a deposition. |
| `get_doi(deposition_id)` | Returns the DOI of a deposition. |

The `dataset` feature drives all of this. In `DataSetService.upload_dataset`, the dataset is persisted
locally first; only then does it create the deposition, upload each feature model, publish, and store
the returned DOI. That second half is deliberately best-effort. If Zenodo fails, the upload is not
lost: the dataset stays in the hub without a DOI and the call returns `{"status": "partial"}` instead
of an error.

## Tests

The feature's tests live next to it, one file per layer:

```
app/features/zenodo/tests/
├── test_unit.py
├── test_repository.py
├── test_service.py
├── test_integration.py
└── test_selenium.py
```

Each file declares its layer at module level, for example `pytestmark = pytest.mark.service` in
`test_service.py`. Run one layer at a time:

```
rosemary test zenodo --unit
rosemary test zenodo --service
rosemary test zenodo --integration
```

`test_service.py` patches `app.features.zenodo.services.requests`, so no network call is ever made and
no token is needed to run it. Only the end-to-end file drives a real browser, and it needs the Selenium
grid from `docker compose -f docker/docker-compose.dev.yml up`:

```
rosemary test zenodo --e2e
```

{: .note }
> The feature's own `/zenodo` route renders a template with an empty content block, so there is nothing
> on that page to look at. What is actually exercised in the browser is the `/zenodo/test` connection
> check, which the dataset upload page calls on load, and the Zenodo record link a synchronized dataset
> shows.
