---
layout: default
parent: Extending uvlhub
grand_parent: Rosemary CLI
title: Composing environment
permalink: /docs/rosemary/extending_uvlhub/composing_environment
nav_order: 2
---

# Composing environment
{: .no_toc }

It is possible to make a final composition of the `.env` file based on the individual `.env` files of each module.

To execute this command and automatically combine the environment variables:

```
rosemary compose:env
```

{: .important-title }
> Reboot required!
> 
> It is necessary to restart the application's Docker container for the changes to take effect:
>
> ```
> docker restart web_app_container
> ```
