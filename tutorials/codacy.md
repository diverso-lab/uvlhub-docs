---
layout: default
title: "CI: Codacy tutorial"
parent: Tutorials
permalink: /tutorials/codacy_tutorial
nav_order: 1
---

# CI: Codacy tutorial
{: .no_toc }

Codacy is a static code analysis tool used to review code quality and ensure that it follows programming best practices. It provides automated analysis across multiple programming languages and helps developers identify issues such as style errors, security issues, code complexity, duplication and more.
{: .fs-6 .fw-300 }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

## Get token from Codacy

- Go to [Codacy.com](https://www.codacy.com). Click the `Start free` button and then the `GitHub` button.
- Add your GitHub account. You must add permission to either all your repositories or the uvlhub repository. We recommend you choose the second option. 
- Go to [Organizations](https://app.codacy.com/organizations) and choose your GitHub username.
- Go to `Repositories` and click on the repository you want to apply Codacy to.
- Go to `Settings` (the cogwheel) and go to `Integrations`.
- Go to the bottom. Under `Repository API tokens` the token you need appears.

## Register the secret in your repository

- In GitHub, in your repository, go to `Settings` -> `Secrets and variables` -> `Actions`.
- Click the green `New repository secret` button.
- In `Name` type `CODACY_PROJECT_TOKEN`.
- In `Secret`, add the token you got from Codacy's `Repository API tokens` field.

## Codacy workflow

In the `.github/workflows` folder you have to add the following `codacy.yml`.

```yml
{% raw %}name: Codacy CI

on:
  push:
    branches:
      - main
  pull_request:
    branches:
      - main

jobs:
  build:
    runs-on: ubuntu-latest
    services:
      mysql:
        image: mysql:5.7
        env:
          MYSQL_ROOT_PASSWORD: uvlhub_root_password
          MYSQL_DATABASE: uvlhubdb_test
          MYSQL_USER: uvlhub_user
          MYSQL_PASSWORD: uvlhub_password
        ports:
          - 3306:3306
        options: --health-cmd="mysqladmin ping" --health-interval=10s --health-timeout=5s --health-retries=3

    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Set up Python
      uses: actions/setup-python@v5
      with:
        python-version: '3.12'

    - name: Install dependencies
      run: |
        python -m pip install --upgrade pip
        pip install -r requirements.txt

    - name: Upload coverage to Codacy
      run: |
        pip install codacy-coverage
        coverage run -m pytest app/modules/ --ignore-glob='*selenium*'
        coverage xml 
        python-codacy-coverage -r coverage.xml
      env:
        FLASK_ENV: testing
        MARIADB_HOSTNAME: 127.0.0.1
        MARIADB_PORT: 3306
        MARIADB_TEST_DATABASE: uvlhubdb_test
        MARIADB_USER: uvlhub_user
        MARIADB_PASSWORD: uvlhub_password
        CODACY_PROJECT_TOKEN: ${{ secrets.CODACY_PROJECT_TOKEN }}{% endraw %}
```

## Try it!

- Make some changes to your code and upload it to GitHub.
- Go to `Repositories` and click on the repository in which you want to study Codacy's analysis.
- There you go!

{: .highlight }
> <i class='fa-solid fa-magnifying-glass-chart'></i> What things do you think we could improve in the code thanks to Codacy's analysis?