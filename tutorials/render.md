---
layout: default
title: "CD: Render tutorial"
parent: Tutorials
permalink: /tutorials/render_tutorial
nav_order: 1
---

# CD: Render tutorial
{: .no_toc }

[Render.com](https://render.com) is a modern hosting and deployment platform that simplifies the deployment of web applications and services. It provides a managed infrastructure that allows developers to focus on code instead of worrying about server configuration and maintenance. With Render, web applications, APIs, databases and static services can be deployed with ease. The platform supports multiple programming languages and frameworks, and provides advanced features such as integrated CI/CD, automatic scaling, and free SSL. In addition, Render offers an intuitive interface and extensive documentation, making the deployment process fast and accessible for beginners and experienced developers alike.

{: .fs-6 .fw-300 }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

{: .important-title }
> <i class="fa-solid fa-boxes-packing"></i> Have you deployed your application in Render?
>
> For this tutorial it is necessary to have previously deployed the project in Render.com.
> If this is not the case, please look at [the Render deployment guide](/deployment/render) first.

## Get token from Render

- Login to Render.com
- Go to [Dashboard](https://dashboard.render.com/). Select the project where you have deployed the app.
- Click on the name of the service. 
- Go to `Settings`. Under `Deploy hook` the token you need appears.

## Disable auto-deploy

By default, any new changes detected in the `main` branch (if you have not chosen another one) will cause the app to
will be deployed again. If we don't want this and we want the deployment to be done under certain conditions in a workflow
of GitHub actions, it is convenient to disable the auto-deployment.

For it, from the same `Settings` tab, in `Auto-Deploy`, we give to `Edit` and select `No`.

## Register the secret in your repository

- In GitHub, in your repository, go to `Settings` -> `Secrets and variables` -> `Actions`.
- Click the green `New repository secret` button.
- In `Name` type `RENDER_DEPLOY_HOOK_URL`.
- In `Secret`, add the token you got from Render's `Deploy hook` field.

## Render continuous deployment workflow

In the `.github/workflows` folder you have to add the following `render.yml`.

```yml
{% raw %}name: Deploy to Render

on:
    push:
      branches:
        - main
    pull_request:
      branches:
        - main

jobs:

  deploy:
    name: Deploy to Render
    runs-on: ubuntu-latest
    steps:
      - name: Check out the repo
        uses: actions/checkout@v4

      - name: Deploy to Render
        env:
          deploy_url: ${{ secrets.RENDER_DEPLOY_HOOK_URL }}
        run: |
          curl "$deploy_url"{% endraw %}
```

## Try it!

- Make some changes to your code and upload it to GitHub (to the synchronized branch in Render)
- Check that the application is deployed again.
- You've got it!