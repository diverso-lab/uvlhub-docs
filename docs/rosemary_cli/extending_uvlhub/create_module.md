---
layout: default
parent: Extending uvlhub
grand_parent: Rosemary CLI
title: Create module
permalink: /docs/rosemary/extending_uvlhub/create_module
nav_order: 4
---

# Create module
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

## About

To quickly generate a new module within the project, including necessary boilerplate files 
like `__init__.py`, `routes.py`, `models.py`, `repositories.py`, `services.py`, `forms.py`,
and a basic `index.html` template, you can use the `rosemary` CLI tool's `make:module` 
command. This command will create a new blueprint structure ready for development.

## Create module

To create a new module, run the following command from the root of the project:

```
rosemary make:module <module_name>
```

Replace `<module_name>` with the desired name of your module.

This command creates a new directory under `app/blueprints/` with the name of your module and sets up the initial files and directories needed to get started, including a dedicated `templates` directory for your module's templates.

This feature is designed to streamline the development process, making it easy to add new features to the project.

{: .note-title }
> Note
>
> If the module with `<module_name>` already exists, `rosemary` will simply notify you and not overwrite any existing files.

