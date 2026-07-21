---
layout: default
parent: CI/CD
title: Continuous deployment
permalink: /ci_cd/continuous_deployment
has_children: true
nav_order: 2
---

# Continuous deployment
{: .no_toc }

Two workflows ship the application, and neither runs on a plain push. Deploying to the server is chained off the `Pytest` workflow and only fires when that run succeeded on `main`. Publishing an image to Docker Hub is a separate path, driven by publishing a GitHub release.

| Workflow | File | Documented in |
|:---|:---|:---|
| `Publish image in Docker Hub` | `.github/workflows/CD_dockerhub.yml` | [Docker Hub workflow]({{site.baseurl}}/ci_cd/continuous_deployment/dockerhub_workflow) |
| `Deploy on Webhook` | `.github/workflows/CD_webhook.yml` | [Webhook workflow]({{site.baseurl}}/ci_cd/continuous_deployment/webhook_workflow) |
