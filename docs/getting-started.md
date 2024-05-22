---
layout: default
title: Getting started
nav_order: 2
---

# Getting started
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

## Installation

To analyze feature models, you can use the `flamapy-fm-dist` distribution. **It requires Python >= 3.9**.  

{: .important }
> It's recommended to use a **virtual environment** (venv) for installation to avoid conflicts with other packages. Here’s how you can set it up:
> ```
> python -m venv flamapyenv && source flamapyenv/bin/activate
> ```   

Install the distribution:

```
pip install flamapy-fm-dist
```

## Basic operations

To test some basic operations, you need UVL models. Several are available at [UVLHub](https://www.uvlhub.io). If you prefer, you can download a test one:

```
wget -q "https://raw.githubusercontent.com/flamapy/flamapy-fm-dist/main/resources/models/valid_model.uvl"
wget -q "https://raw.githubusercontent.com/flamapy/flamapy-fm-dist/main/resources/configurations/valid_configuration.csvconf"
```

### Validate the model

To check if the model is valid, run:

```
flamapy-fm-cli --modelPath="./valid_model.uvl" valid
```

### Get all products

To generate all possible products from the model, use:

```
flamapy-fm-cli --modelPath="./valid_model.uvl" products
```

### Validate a configuration

To verify if a specific configuration is valid, run:


```
flamapy-fm-cli --modelPath="./valid_model.uvl" valid_configuration ./valid_configuration.csvconf
```

## I want to use more feature models analysis operations

{% include flamapy.html %} runs on a framework based on `Core / Plugins` architecture. If you are interested in more feature model operations, you have several options:

### Option 1: using the feature models distribution.

We have prepared the `flamapy-fm-dist` distribution which acts as an interface and is specific to feature models.

### Option 2: Without using the feature models distribution

You can choose not to use the distribution. In that case, **you have to install the core and the corresponding plugin in developer mode**.

To set up your environment in developer mode and work directly with the plugins, visit the section ['Setting the development environment']({{site.baseurl}}/docs/developing/setting_development_environment/)

You can check the rest of [operations]({{site.baseurl}}/docs/core_and_plugins/fm/) of the plugin for feature models.

## I want to use more operations other plugins.

Of course, {% include flamapy.html %} incorporates more plugins. In blabla you can check the rest of plugins.
