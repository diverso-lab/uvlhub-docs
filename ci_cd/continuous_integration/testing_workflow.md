---
layout: default
grand_parent: CI/CD
parent: Continuous integration
title: Testing workflow
permalink: /ci_cd/continuous_integration/testing_workflow
nav_order: 1
---


# Testing workflow
{: .no_toc }

{: .important-title }
>
> Path to file [(view file on GitHub)](https://github.com/diverso-lab/uvlhub/blob/main/.github/workflows/test.yml)
> 
> The original file is located at the following path:
>
> ```
> .github / workflows / test.yml 
> ```

This GitHub Actions workflow is designed to automate the Continuous Integration (CI) process for a Flask application. It triggers on pushes and pull requests to the `main` and `develop` branches. The essential elements of this workflow are as follows:

{: .no_toc .text-delta }

1. TOC
{:toc}


## Workflow Name
- **name**: Run tests

## Triggers
- **on**: 
  - **push**: Triggers on pushes to `main` and `develop` branches.
  - **pull_request**: Triggers on pull requests to `main` and `develop` branches.

## Jobs
- **pytest**: This job runs on the latest Ubuntu environment (`ubuntu-latest`).

### Services
- **mysql**: Sets up a MySQL 5.7 service with the following environment variables and options for health checks:
  - `MYSQL_ROOT_PASSWORD`: `uvlhub_root_password`
  - `MYSQL_DATABASE`: `uvlhubdb_test`
  - `MYSQL_USER`: `uvlhub_user`
  - `MYSQL_PASSWORD`: `uvlhub_password`
  - Ports: `3306:3306`
  - Health check options: `--health-cmd="mysqladmin ping" --health-interval=10s --health-timeout=5s --health-retries=3`

### Steps
1. **Checkout Repository**
   - Uses the `actions/checkout@v4` action to checkout the repository.

2. **Setup Python**
   - Uses the `actions/setup-python@v5` action to set up Python 3.12.

3. **Prepare Environment**
   - Runs a command to modify the `requirements.txt` file, removing a specific line.

4. **Install Dependencies**
   - Upgrades `pip` and installs dependencies from `requirements.txt`.

5. **Run Tests**
   - Sets environment variables for testing and runs `pytest` on the Flask application.

### Environment Variables for Tests
- `FLASK_ENV`: `testing`
- `MARIADB_HOSTNAME`: `127.0.0.1`
- `MARIADB_PORT`: `3306`
- `MARIADB_TEST_DATABASE`: `uvlhubdb_test`
- `MARIADB_USER`: `uvlhub_user`
- `MARIADB_PASSWORD`: `uvlhub_password`
