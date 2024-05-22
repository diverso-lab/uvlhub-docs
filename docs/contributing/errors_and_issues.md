---
layout: default
title: Errors and issues
parent: Contributing
grand_parent: Developing
permalink: /docs/developing/contributing/errors_and_issues
nav_order: 3
---

# Errors and issues
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

## Error Handling

### Errors outside the scope of your work

1. Make sure it is an actual error and not a bad interaction between your code and the rest of the project.
2. [Open an issue]({{site.baseurl}}/docs/contributing/errors_and_issues/#guidelines-for-creating-issues) to keep track of the error.
3. You can assign the issue yourself if you either want to fix the error or need to do so for your code to work. If you want to fix that new issue, you SHOULD do it from a different PR. If it is impossible or too hard to separately fix it, fix the error on your already open PR, but you MUST clarify which commits are part of this new issue so maintainers know it when squashing.

### Errors in your own code

Fix it as soon as possible to prevent it from scaling.

## Issue Management

### Guidelines for creating issues

You can open an issue any time you find a bug or an idea to implement in a project. Whatever the reason is, issues will keep track of the remaining and finished tasks in projects. To keep the issues environment as efficient as possible, please consider the following practices:

* Provide a descriptive short title. Use description to give more in-depth details.
* Use labels to make your issues easier to filter.
* For bugs, try to find and mention the author of the code which is failing.
* For bugs, include as many details as possible to make them replicable and testable.
* Keep your notifications on so you know about mentions or comments on your issues.
