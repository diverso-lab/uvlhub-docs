---
layout: default
title: Zenodo
parent: Modules
permalink: /docs/modules/zenodo
nav_order: 1
---

# Zenodo

To use Zenodo module, it is important to obtain a token in Zenodo first.

{: .warning }
**We recommend creating the token in the Sandbox version of Zenodo, in order to generate fictitious DOIs 
and not make intensive use of the real Zenodo SLA.**

To generate the Zenodo `.env` file, run in root project:

```
cp app/blueprints/zenodo/.env.example app/blueprints/zenodo/.env
```

To perform the composition of all environment variables, refer to section [Composing Environment Variables](#composing-environment-variables).