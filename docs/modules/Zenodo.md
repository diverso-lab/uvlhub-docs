---
layout: default
title: Zenodo
parent: Modules
permalink: /docs/modules/zenodo
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

To use Zenodo module, it is important to obtain a token in Zenodo first.

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

To generate the Zenodo `.env` file in `app/blueprints/zenodo`, run in root project:

```
cp app/blueprints/zenodo/.env.example app/blueprints/zenodo/.env
```

## Include your access token

In the generated `.env`file, you must include the access token obtained in Zenodo:

```
ZENODO_ACCESS_TOKEN=<GET_ACCESS_TOKEN_IN_ZENODO>
```

{: .important-title }
> A composition of variables is necessary!
>
> To perform the composition of all environment variables, refer to section [Composing environment]({{site.baseurl}}/docs/rosemary/extending_uvlhub/composing_environment).
