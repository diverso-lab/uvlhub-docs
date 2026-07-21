---
layout: default
grand_parent: CI/CD
parent: Continuous integration
title: Commit syntax checker workflow
permalink: /ci_cd/continuous_integration/commit_syntax_checker_workflow
nav_order: 3
---

# Commit syntax checker workflow
{: .no_toc }

{: .important-title }
>
> Path to file [(view file on GitHub)](https://github.com/diverso-lab/uvlhub/blob/main/.github/workflows/CI_commits.yml)
> 
> The original file is located at the following path:
>
> ```
> .github / workflows / CI_commits.yml 
> ```

This GitHub Actions workflow validates commit messages against the [Conventional Commits](https://www.conventionalcommits.org/) specification. It is the shortest workflow in the repository: a single step, and no checkout.

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

## Workflow name

- **name**: `Commits Syntax Checker`

## Triggers

```yaml
on:
  push:
  pull_request:
```

Both triggers are bare, with no branch filter, so the check runs on every branch and every pull request. You find out that a commit message is malformed on the branch, while it is still cheap to rewrite.

## Job

- **check**, named `Conventional Commits`, runs on `ubuntu-24.04`.

## Steps

```yaml
- name: Validate commit messages
  uses: webiny/action-conventional-commits@v1.3.0
```

That is the entire job.

Note that there is no `actions/checkout` step. The action reads the commit messages from the GitHub API using the event payload, so it never needs a working copy of the repository. Adding a checkout step here would only make the job slower.

## What a valid commit message looks like

The message must start with a type, an optional scope in parentheses, a colon, a space and a description:

```
<type>(<optional scope>): <description>
```

Valid examples:

```
feat: add dataset export to CSV
fix(auth): reject expired password reset tokens
docs: document the pytest workflow
refactor(dataset): extract rating logic into the service
test(hubfile): add repository tests for file lookup
chore: bump splent_framework to 1.6.1
```

Messages that fail the check:

```
updated stuff
Fix bug
feat add export
```

A breaking change is marked with `!` before the colon:

```
feat(dataset)!: drop support for the legacy upload endpoint
```

## Fixing a rejected commit

If the check fails, rewrite the offending message rather than adding a new commit on top. For the most recent commit:

```bash
git commit --amend -m "feat(dataset): add dataset export to CSV"
git push --force-with-lease
```

For an older commit in the branch, rewrite the range interactively and reword the commits that were rejected:

```bash
git rebase -i origin/main
git push --force-with-lease
```

{: .warning-title }
> Force pushing
>
> Only force push to your own branch. Use `--force-with-lease` rather than `--force`, so that the push is
> refused if somebody else has pushed to the branch in the meantime.
