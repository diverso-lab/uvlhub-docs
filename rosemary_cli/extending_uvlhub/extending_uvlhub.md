---
layout: default
parent: Rosemary CLI
title: Extending uvlhub
has_children: yes
permalink: /rosemary/extending_uvlhub
nav_order: 2
---

# Extending uvlhub
{: .no_toc }

New functionality in {% include uvlhub.html %} arrives as a **feature**: a self-contained package
under `app/features/` that owns its blueprint, model, repository, service, form, seeder, templates,
assets and tests. Base classes come from the `splent_framework` package, and the set of features the
application loads is declared in the root `pyproject.toml` under `[tool.splent]`.

These pages cover the two `rosemary` commands you need to add one:

- [Create feature]({{site.baseurl}}/rosemary/extending_uvlhub/create_feature) scaffolds the package
  and its six test files with `rosemary feature:create`.
- [Composing environment]({{site.baseurl}}/rosemary/extending_uvlhub/composing_environment) merges
  per-feature `.env` files into the root one with `rosemary compose:env`.

For a worked example that takes a feature from scaffold to a full C.R.U.D., follow the
[C.R.U.D. tutorial]({{site.baseurl}}/tutorials/crud_tutorial).
