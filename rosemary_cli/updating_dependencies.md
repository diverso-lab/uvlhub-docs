---
layout: default
parent: Rosemary CLI
title: Updating dependencies
permalink: /rosemary/updating_dependencies
nav_order: 6
---

# Updating dependencies
{: .no_toc }

To update all project dependencies, run:

```
rosemary update
```

This updates the pip dependencies first and the npm dependencies afterwards.

## How the pip update works

The pip half does not simply upgrade packages in place. It:

1. Builds a temporary requirements file from `requirements.txt` with every version pin stripped.
2. Uninstalls all non-editable packages from the environment.
3. Installs the unpinned requirements, resolving each dependency to its latest available version.
4. Rewrites `requirements.txt` from the output of `pip freeze`, so the file ends up pinned to the newly resolved
   versions.
5. Reinstalls the editable package (the `-e` line) if `requirements.txt` declared one.

In other words, running the command **modifies `requirements.txt`**. Review the resulting diff before committing it.

## Updating pip or npm only

Each half is also exposed as its own command:

```
rosemary update:pip
rosemary update:npm
```

`rosemary update:npm` looks for a `package.json` at the project root and, if it finds one, runs
`npx npm-check-updates -u` followed by `npm install`. This project has no `package.json` at the root, so the npm
half is currently a no-op: it prints `No package.json found. Skipping npm update.` and finishes.

{: .warning }
It is the responsibility of the developer to check that the update of the dependencies has not broken any 
functionality and each dependency maintains backwards compatibility. **Use the script with care!**
