---
layout: default
title: Extending with your plugins
parent: Developing
nav_order: 2
---

# Extending with your plugins
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

{: .important }
> In order to use the CLI, you need to [set the development environment]({{site.baseurl}}/docs/developing/setting_development_environment/)

## Create your own plugin

{: .highlight }
Let's take as an example that we want to develop a plugin for OVM (Orthogonal Variability Model)

We go to the `core` repository of {% include flamapy.html %} and create a directory for the metamodel:

```
cd core && mkdir ./ovm_metamodel
```

We use the `flamapy-admin` CLI to generate the new plugin:

```
flamapy-admin new_plugin --path ./ovm_metamodel ovm ovm
```
