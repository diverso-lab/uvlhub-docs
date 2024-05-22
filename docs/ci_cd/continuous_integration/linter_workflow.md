---
layout: default
grand_parent: CI/CD
parent: Continuous integration
title: Linter workflow
permalink: /docs/ci_cd/continuous_integration/linter_workflow
nav_order: 2
---

# Linter workflow
{: .no_toc }

{: .important-title }
>
> Path to file [(view file on GitHub)](https://github.com/diverso-lab/uvlhub/blob/main/.github/workflows/lint.yml)
> 
> The original file is located at the following path:
>
> ```
> .github / workflows / lint.yml 
> ```

This GitHub Actions workflow is designed to automate the linting process for a Python application using flake8. It triggers on both pushes and pull requests. The essential elements of this workflow are as follows:


## Workflow Name
- **name**: Python Lint

## Triggers
- **on**: 
  - **push**: Triggers on any push to the repository.
  - **pull_request**: Triggers on any pull request to the repository.

## Jobs
- **build**: This job runs on the latest Ubuntu environment (`ubuntu-latest`).

### Steps
1. **Checkout Repository**
   - Uses the `actions/checkout@v2` action to checkout the repository.

2. **Set up Python**
   - Uses the `actions/setup-python@v2` action to set up Python 3.x.

3. **Install Dependencies**
   - Upgrades `pip` and installs `flake8` using the following commands:
     ```bash
     python -m pip install --upgrade pip
     pip install flake8
     ```

4. **Lint with flake8**
   - Runs `flake8` on the `app` directory to lint the Python code:
     ```bash
     flake8 app
     ```




