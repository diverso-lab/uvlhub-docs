---
layout: default
title: Rosemary CLI
has_children: true
permalink: /docs/rosemary
nav_order: 6
---

# Rosemary CLI

`Rosemary` is a CLI (Command Line Interface) tool developed to facilitate project management and development tasks.

To use the Rosemary CLI, you need to be inside the `web_app_container` Docker container. This ensures that Rosemary operates in the correct environment and has access to all necessary files and settings.

First, make sure your Docker environment is running. Then, access the `web_app_container` using the following command:

```
docker exec -it web_app_container /bin/sh
```

In the terminal, you should see the prefix `/app #`. You are now ready to use Rosemary's commands.