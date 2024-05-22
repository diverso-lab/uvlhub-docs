---
layout: default
title: Overview
parent: Architecture
permalink: /docs/architecture/overview
nav_order: 3
---

# Overview
{: .no_toc }

The architecture of uvlhub consists of five main components. 

{: .no_toc .text-delta }

1. TOC
{:toc}

![UVLHUB Architecture Overview](/assets/images/uvlhub_architecture.svg)
*Figure 1: Overview of UVLHUB architecture.*

## Web application

The primary access point for the web application is through a web browser. Users navigate to a domain that redirects them to the Flask-developed application[^1]. {% include uvlhub.html %} integrates four distinct services: (2) local storage for UVL models and pertinent information, (3) Zenodo for permanent data persistence, (4) automatic feature model analysis, and (5) a RESTful service to extend functionality to other domains.

## Local Storage

Users upload their models in the UVL format. All uploaded models must be syntactically valid, conforming to UVL grammar. However, models might still contain semantic errors such as dead features or conflicting constraints[^2]. UVL files are stored locally, while related information like title, description, authors, and tags are stored in a relational database.

## Zenodo

Although some model data is stored locally, it is backed up in the Zenodo general repository. This provides the UVL datasets with a DOI, facilitating the process of obtaining the identifier. If {% include uvlhub.html %} becomes unavailable, the datasets remain on Zenodo, allowing local storage to be rebuilt without data loss.

## Automated Analysis of Feature Models (AAFM)

Users can analyze[^2] the models within their datasets uploaded to {% include uvlhub.html %}. This analysis, supported by the {% include flamapy.html %} tool suite[^3], can determine model validity, feature count, or the number of different products derivable from the model. This component ensures each model's syntactic correctness, delegating syntax verification responsibility to {% include uvlhub.html %}, thus sparing users from performing this check.

## REST API

Open Science advocates for open access to research data, making data generated in scientific research freely available and accessible to other researchers, practitioners, and the public. To support this, {% include uvlhub.html %} offers a REST API accessible to any registered user with a developer role. This API allows free integration of validated and analyzed models (from component 4) into other domains.

[^1]: Flask: [Flask Project](https://flask.palletsprojects.com)
[^2]: AAFM: "Feature Models 20 Years Later: A Systematic Literature Review"
[^3]: Galindo, J. A., et al. (2023). "FLAMA: Feature Model Analysis Tool Suite"
