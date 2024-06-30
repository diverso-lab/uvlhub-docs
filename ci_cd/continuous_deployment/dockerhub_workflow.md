---
layout: default
grand_parent: CI/CD
parent: Continuous deployment
title: Docker Hub workflow
permalink: /ci_cd/continuous_deployment/dockerHub_workflow
nav_order: 3
---

# Docker Hub workflow
{: .no_toc }

{: .note-title }
>
> Path to file [(view file on GitHub)](https://github.com/diverso-lab/uvlhub/blob/main/.github/workflows/deployment.yml)
> 
> The original file is located at the following path:
>
> ```
> .github / workflows / deployment_on_dockerhub.yml 
> ```

{: .important-title }
> To register secrets in GitHub:
>
>1. Navigate to your repository on GitHub.
>2. Click on `Settings`.
>3. In the left sidebar, click on `Secrets and variables` and then `Actions`.
>4. Click the `New repository secret` button.
>5. Add a name for your secret (e.g., `DOCKER_USER`) and its value.
>6. Click `Add secret` to save.
> 
> Repeat these steps for  `DOCKER_PASSWORD` secret.

This GitHub Actions workflow is designed to automate the process of building and publishing Docker images to Docker Hub whenever a new release is published. The essential elements of this workflow are as follows:

## Workflow Name
- **name**: Publish image in Docker Hub

## Triggers
- **on**: 
  - **release**: Triggers when a release is published.

## Jobs
- **push_to_registry**: This job runs on the latest Ubuntu environment (`ubuntu-latest`).

### Steps
1. **Check out the Repository**
   - Uses the `actions/checkout@v3` action to checkout the repository.

2. **Log in to Docker Hub**
   - Uses the `docker/login-action` pinned to a specific commit (`f4ef78c080cd8ba55a85445d5b36e214a81df20a`) to log in to Docker Hub with credentials stored in GitHub Secrets:
     ```yaml
     username: ${{ secrets.DOCKER_USER }}
     password: ${{ secrets.DOCKER_PASSWORD }}
     ```

3. **Build and Push Docker Image**
   - Builds the Docker image using the `Dockerfile.prod` file and tags it with the release tag name:
     ```bash
     docker build -t drorganvidez/uvlhub:${{ github.event.release.tag_name }} -f Dockerfile.prod .
     ```
   - Pushes the tagged Docker image to Docker Hub:
     ```bash
     docker push drorganvidez/uvlhub:${{ github.event.release.tag_name }}
     ```

4. **Tag and Push Latest**
   - Tags the built Docker image with `latest` and pushes it to Docker Hub:
     ```bash
     docker tag drorganvidez/uvlhub:${{ github.event.release.tag_name }} drorganvidez/uvlhub:latest
     docker push drorganvidez/uvlhub:latest
     ```

### Notes
- **Third-Party Actions**: This workflow uses third-party actions that are not certified by GitHub. They are governed by separate terms of service, privacy policy, and support documentation.
- **Pinning Actions**: GitHub recommends pinning actions to a commit SHA to ensure stability and predictability. The workflow uses a pinned commit SHA for the Docker login action.