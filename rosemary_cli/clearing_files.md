---
layout: default
parent: Rosemary CLI
title: Clearing files
permalink: /rosemary/clearing_files
nav_order: 7
---

# Clearing files
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

All three commands resolve their paths against `WORKING_DIR`, so they act on the project as seen from the
environment you run them in.

## Clear cache

```
rosemary clear:cache
```

This clears the `build` directory and the compiled bytecode left around the project. It asks for confirmation first.
Once confirmed, it removes:

- `build/`
- every `__pycache__` directory found anywhere under the project root
- every `.pyc` file found anywhere under the project root

It also looks for `app/features/.pytest_cache`, but that directory does not exist: pytest's rootdir is the project
root, so the cache is written to `.pytest_cache` at the top level and `clear:cache` leaves it alone. Delete it by
hand if you need to. The `__pycache__` and `.pyc` sweep is the part of this command that does the real work.

Useful after switching between the local, Docker and Vagrant environments, which write bytecode into the same
working tree with different interpreters.

## Clear log

```
rosemary clear:log
```

This deletes the `app.log` file. The file is recreated by the application the next time it logs something.

## Clear uploads

```
rosemary clear:uploads
```

This empties the `uploads` folder used to store uploaded dataset files, without removing the folder itself. It
deletes files, symlinks and subdirectories alike.

The folder name is read from the `UPLOADS_DIR` environment variable and defaults to `uploads`, so if you have
overridden that variable the command follows it.

{: .warning-title }
> <i class="fa-solid fa-triangle-exclamation"></i> This one does not ask
>
> `clear:uploads` deletes without a confirmation prompt, and `rosemary db:reset` invokes it as part of its own
> cleanup. Do not run either against a directory that holds data you care about.
