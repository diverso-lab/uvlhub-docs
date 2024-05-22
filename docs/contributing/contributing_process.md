---
layout: default
title: Contributing process
grand_parent: Developing
parent: Contributing
permalink: /docs/developing/contributing/contributing_process
nav_order: 1
---

# Contributing process
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

## I want to contribute to the project. What should I do?

### Find an issue

 Find one issue you want to resolve. Make sure nobody else is working on such issue.
 
### Follow Development guide

Follow the [Setting development environment]({{site.baseurl}}/docs/developing/setting_development_environment/) to set up the project. Consider you will have to fork the project you want to contribute to.

### Create a new branch

Create a new [branch]({{site.baseurl}}/docs/contributing/branch_and_commit_guidelines/#branch-naming-conventions) from develop in your forked project.
```
git branch new-branch develop
```

### Make an empty commit

Make an [empty commit]({{site.baseurl}}/docs/contributing/branch_and_commit_guidelines/#first-commit-requirements) on this branch and push.
```bash
git commit -m 'message' --allow-empty
git push -u origin new-branch
```

### Create a PR

Create a PR with this empty commit, from your new branch, to base repository's develop branch. This PR's name must end with a keyword such as `solves` or `fixes` followed by the issue it solves (e.g., `solves #115`)

### Commit and push changes

From this, any change you commit and push to your branch will be added to the PR. Keep [committing](#how-should-i-commit) until you finish developing your contribution and mention a maintainer so they can revise it. Check [this](#what-do-i-have-to-do-to-get-my-request-accepted) to know the requisites to get you request accepted.

## What can I contribute to?

You can contribute to any of the issues in any project.