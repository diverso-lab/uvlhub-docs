---
layout: default
title: Branch and Commit Guidelines
parent: Contributing
grand_parent: Developing
permalink: /docs/developing/contributing/branch_and_commit_guidelines
nav_order: 2
---

# Branch and Commit Guidelines
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

## Branch naming conventions

Branches should follow a `<token>-<short-descriptive-name>` structure, where tokens can be such as:

- **chore**: Improvement on project maintenance or administration, such as dependencies updates.
- **docs**: Documentation creation or update.
- **feature**: New features added to the project.
- **fix/hotfix/patch**: Correction of bugs and errors.
- **refactor**: Improvement of already written code, with no changes on functionality.
- **test**: Addition or updates of tests to features.

## Commit guidelines

### Descriptive and atomic commits

Commits should be as **descriptive** and **atomic** as possible. However, commits collaborators make on their PRs will not be logged, as they will always be squashed.

For this reason, you will not have to worry much about commit messages following strict guidelines. Just see your commit history as a log for both maintainers and you to know the progress of the work.

### First commit requirements

A first and mandatory commit has to be done, as mentioned before, to create the PR. This commit should contain a brief description of the remaining work.