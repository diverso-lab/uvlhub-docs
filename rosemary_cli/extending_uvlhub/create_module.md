---
layout: default
parent: Extending uvlhub
grand_parent: Rosemary CLI
title: Create module
permalink: /rosemary/extending_uvlhub/create_module
nav_order: 1
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
command. This command will create a new module structure ready for development.

## Create module

To create a new module, run:

```
rosemary make:module <module_name>
```

Replace `<module_name>` with the desired name of your module.

This command creates a new directory under `app/modules/` with the name of your module and sets up the initial files and directories needed to get started, including a dedicated `templates` directory for your module's templates.

This feature is designed to streamline the development process, making it easy to add new features to the project.

{: .note-title }
> Note
>
> If the module with `<module_name>` already exists, `rosemary` will simply notify you and not overwrite any existing files.

{: .important-title }
> Reboot required!
> 
> It is necessary to restart the application's Docker container for the changes to take effect:
>
> ```
> docker restart web_app_container
> ```
