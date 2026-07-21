---
layout: default
parent: CI/CD
title: Continuous integration
permalink: /ci_cd/continuous_integration
has_children: true
nav_order: 1
---

# Continuous integration
{: .no_toc }

Three workflows guard every change. The linter and the commit message checker run on every push to every branch, so style and commit history problems surface on the branch. The test suite runs only for `main`: when a pull request targets it, and again when the merge lands.

| Workflow | File | Documented in |
|:---|:---|:---|
| `Pytest` | `.github/workflows/CI_pytest.yml` | [Testing workflow]({{site.baseurl}}/ci_cd/continuous_integration/testing_workflow) |
| `Python Lint` | `.github/workflows/CI_lint.yml` | [Linter workflow]({{site.baseurl}}/ci_cd/continuous_integration/linter_workflow) |
| `Commits Syntax Checker` | `.github/workflows/CI_commits.yml` | [Commit syntax checker workflow]({{site.baseurl}}/ci_cd/continuous_integration/commit_syntax_checker_workflow) |
