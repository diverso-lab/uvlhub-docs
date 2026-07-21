---
layout: default
grand_parent: CI/CD
parent: Continuous deployment
title: Docker Hub workflow
permalink: /ci_cd/continuous_deployment/dockerHub_workflow
nav_order: 1
---

# Docker Hub workflow
{: .no_toc }

{: .important-title }
>
> Path to file [(view file on GitHub)](https://github.com/diverso-lab/uvlhub/blob/main/.github/workflows/CD_dockerhub.yml)
> 
> The original file is located at the following path:
>
> ```
> .github / workflows / CD_dockerhub.yml 
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

This GitHub Actions workflow builds the production Docker image and publishes it to Docker Hub whenever a new release is published on GitHub.

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

## Workflow name

- **name**: `Publish image in Docker Hub`

## Triggers

```yaml
on:
  release:
    types: [published]
```

The workflow runs only when a release is *published*. Creating a tag is not enough, and neither is saving a draft release. The release tag name is what ends up as the image tag, so tag your releases the way you want your images named.

## Job

- **push_to_registry**: runs on `ubuntu-24.04`.

## Steps

### 1. Checkout

```yaml
- uses: actions/checkout@v5
```

The build needs the working copy, because the image is built from the repository contents.

### 2. Log in to Docker Hub

```yaml
- name: Log in to Docker Hub
  uses: docker/login-action@v3.6.0
  with:
    username: ${{ secrets.DOCKER_USER }}
    password: ${{ secrets.DOCKER_PASSWORD }}
```

Both credentials come from repository secrets. Use a Docker Hub access token as `DOCKER_PASSWORD` rather than your account password, so you can revoke it without changing your account.

### 3. Build and push

```yaml
- name: Build and push Docker image
  run: |
    TAG=${{ github.event.release.tag_name }}
    IMAGE=${{ secrets.DOCKER_USER }}/uvlhub

    docker build --build-arg VERSION_TAG=$TAG -t $IMAGE:$TAG -f docker/images/Dockerfile.prod .
    docker push $IMAGE:$TAG

    docker tag $IMAGE:$TAG $IMAGE:latest
    docker push $IMAGE:latest
```

Three things are worth noticing here.

**The image name is not hardcoded.** It is built from the `DOCKER_USER` secret, so the repository publishes to whatever account owns the credentials. If you fork {% include uvlhub.html %} and set your own secrets, the workflow publishes to `<your-user>/uvlhub` without any change to the YAML.

**The Dockerfile lives under `docker/images/`.** The build file is `docker/images/Dockerfile.prod` and the build context is the repository root (`.`). The context matters: the Dockerfile copies `app/`, `migrations/`, `requirements.txt` and `scripts/wait-for-db.sh` from the root.

**`VERSION_TAG` is passed into the build.** `Dockerfile.prod` declares `ARG VERSION_TAG` and writes it into a file inside the image:

```dockerfile
ARG VERSION_TAG
RUN echo $VERSION_TAG > /workspace/.version
```

That is how a running container knows which release it came from. Note that the working directory inside the image is `/workspace`, not `/app`.

Every release therefore produces two pushes: the immutable `:<tag>` image, and a moving `:latest` pointer.

### Verifying the published image

Once the workflow has finished, you can pull the image and read the version file back out:

```bash
docker pull <your-user>/uvlhub:latest
docker run --rm <your-user>/uvlhub:latest cat /workspace/.version
```

## Notes

- **Third-party actions**: this workflow uses `docker/login-action`, which is not certified by GitHub. It is governed by separate terms of service, privacy policy and support documentation.
- **Action pinning**: `docker/login-action` is pinned to the release tag `v3.6.0`, not to a commit SHA. A version tag is mutable, so pinning to a full commit SHA is stricter and is what GitHub recommends for supply-chain hardening. Pinning to a tag is the trade-off this repository has chosen: it stays readable and still prevents an unreviewed major version from being pulled in.
