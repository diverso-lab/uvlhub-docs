---
layout: default
grand_parent: CI/CD
parent: Continuous integration
title: Commit syntax checker workflow
permalink: /docs/ci_cd/continuous_integration/commit_syntax_checker_workflow
nav_order: 3
---

# Commit syntax checker workflow
{: .no_toc }

{: .important-title }
>
> Path to file [(view file on GitHub)](https://github.com/diverso-lab/uvlhub/blob/main/.github/workflows/commits.yml)
> 
> The original file is located at the following path:
>
> ```
> .github / workflows / commits.yml 
> ```

This GitHub Actions workflow is designed to enforce conventional commit syntax on commits and pull requests. It triggers on various pull request events and pushes to the `main` branch. The essential elements of this workflow are as follows:

## Workflow Name
- **name**: Commits Syntax Checker

## Triggers
- **on**: 
  - **pull_request**: Triggers on the following events for the `main` branch:
    - `opened`
    - `reopened`
    - `edited`
    - `review_requested`
    - `synchronize`
  - **push**: Triggers on any push to the `main` branch.
  - **workflow_call**: Allows the workflow to be called by other workflows.

## Jobs
- **check**: This job runs on the latest Ubuntu environment (`ubuntu-latest`).

### Steps
1. **Checkout Repository**
   - Uses the `actions/checkout@v2` action to checkout the repository.

2. **Conventional Commits Check**
   - Uses the `webiny/action-conventional-commits@v1.0.3` action to ensure that commit messages follow conventional commit standards.