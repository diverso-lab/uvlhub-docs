---
layout: default
title: Rosemary CLI
has_children: true
permalink: /rosemary
nav_order: 6
---

# Rosemary CLI

`Rosemary` is a CLI (Command Line Interface) tool developed to facilitate project management and development tasks.
{: .fs-6 .fw-300 }

## Advantages of Using a CLI

### Common usage point

A CLI provides a standardized interface for executing commands, making it easier for users to perform a wide range of tasks from a single point.

### Command unification

With a CLI, commands are unified under a single tool, reducing the need to remember different commands for different environments or tools. This unification streamlines workflows and enhances productivity.

### Environment problem resolution

Rosemary detects the environment in which it is running, whether local, Docker, or Vagrant. This capability acts as a layer that simplifies environment management, automatically adjusting its behavior to suit the detected environment and minimizing the potential for environment-specific issues.

### Efficiency and speed

CLIs are typically faster than graphical user interfaces (GUIs) because they require fewer resources and can execute commands more quickly without the overhead of graphical elements.

### Automation

A CLI can be easily scripted, allowing for the automation of repetitive tasks. This feature is particularly beneficial in development and project management, where certain tasks need to be performed frequently and consistently.

By incorporating these advantages, Rosemary enhances the efficiency and effectiveness of project management and development processes, providing a robust tool for developers and project managers alike.

## Commands not covered elsewhere

Most Rosemary commands have their own page in this section (or in the testing and database subsections). Two entries
in `rosemary --help` do not, so they are documented here.

### rosemary zip

```
rosemary zip <uvus>
```

Generates a delivery archive named `egc_<uvus>_entrega.zip` at the project root, where `<uvus>` is a required
argument (your UVUS username). The command:

- Requires exactly one `.pdf` file at the project root; with zero or more than one it stops with an error.
- Asks for confirmation before overwriting an `egc_<uvus>_entrega.zip` that already exists.
- Excludes virtual environments, `rosemary.egg-info`, `__pycache__` directories, the `.env` file, `app.log`, and any
  existing `.zip` files from the archive.

### rosemary cli

`rosemary --help` also lists a `cli` command described as "Manage updates for pip and npm dependencies." It is not a
separate feature: Rosemary auto-registers every Click command it finds in its command modules, and that sweep picks
up the internal Click group named `cli` that holds the update logic. Its only subcommand is `update`, so
`rosemary cli update` is just a redundant spelling of `rosemary update`. You can safely ignore it.