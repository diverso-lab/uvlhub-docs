---
layout: default
parent: Extending uvlhub
grand_parent: Rosemary CLI
title: Composing environment
permalink: /rosemary/extending_uvlhub/composing_environment
nav_order: 2
---

# Composing environment
{: .no_toc }

A feature that needs its own configuration can ship a `.env` file next to its code, in
`app/features/<feature_name>/.env`. `rosemary compose:env` walks `app/features/`, collects every
`.env` it finds and merges them into the root `.env`.

To run the composition:

```
docker exec -it web_app_container rosemary compose:env
```

The root `.env` wins. If a feature declares a variable that already exists at the root with a
different value, the feature value is discarded and you get a warning naming the file:

```
Conflict found for variable 'ZENODO_ACCESS_TOKEN' in /workspace/app/features/zenodo/.env. Keeping the original value.
```

Variables that do not clash are added. The command always finishes with:

```
Successfully merged .env files without conflicts.
```

even when it reported conflicts above. Read the yellow conflict lines, not the final line, to know
whether anything was discarded.

{: .note-title }
> Note
>
> Features ship a `.env.example` rather than a `.env`, since real credentials never belong in the
> repository. `app/features/zenodo/.env.example` is the reference case. Copy it to `.env` in the same
> directory, fill in your value, and then run `compose:env`.

{: .important-title }
> Reboot required!
>
> Environment variables are read at startup, so restart the application container for the merged
> values to take effect:
>
> ```
> docker restart web_app_container
> ```

You can check the result without opening the file:

```
docker exec -it web_app_container rosemary env
```
