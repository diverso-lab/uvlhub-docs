---
layout: default
title: CLI
parent: Developing
nav_order: 2
---

# CLI
{: .no_toc }

{% include flamapy.html %} provides `flamapy_admin`, a CLI (Command Line Interface) with which to perform common development operations while the plugin is being developed.

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

{: .important }
> In order to use the CLI, you need to [set the development environment]({{site.baseurl}}/docs/developing/setting_development_environment/)

## Get availables plugins 

To list all plugins that are available for use in the core, run:

```
flamapy-admin cli get_plugins
```

## Get available operations of a plugin

To list all available operations of a specific plugin, run:

```
flamapy-admin cli get_operations_name_by_plugin NAME_PLUGIN
```

## Create new plugins

You can create a new plugin with the following command structure:

```
flamapy_admin.py new_plugin --path PLUGIN_PATH NAME_PLUGIN EXTENSION_PLUGIN
```

For example, suppose we want to develop a plugin for OVM (Orthogonal Variability Model). The command would be:

```
flamapy_admin.py new_plugin --path /path/to/my/plugin/ovm_metamodel ovm ovm
```