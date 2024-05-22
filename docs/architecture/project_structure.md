---
layout: default
title: Project structure
parent: Architecture
permalink: /docs/architecture/project_structure
nav_order: 3
---

# Project structure
{: .no_toc }

This section provides an overview of the directory and file structure of the project. Each subsection describes the purpose and contents of specific directories and files, highlighting their roles within the overall architecture. Understanding this structure is crucial for effective development, maintenance, and deployment of the application. Below is a detailed explanation of each component in the project.

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

## .github/workflows
This directory contains GitHub Actions workflows. These YAML files define automated actions that run on specific repository events, such as pushes or pull requests.

## app
This directory likely contains the main application code. It includes modules, views, controllers, and other fundamental components of the application's business logic.

## core
This directory usually contains core components and services used throughout the application. It can include utilities, global configurations, and base classes.

## letsencrypt
This directory is related to Let's Encrypt, a free certificate authority. It contains scripts and configurations for the automatic generation of SSL certificates.

## migrations
This directory contains database migration files, which allow incremental changes to the database schema in a controlled and reproducible manner.

## nginx
This directory contains configurations for the NGINX web server, which is used to serve the application, handle HTTP traffic, and perform other network-related tasks.

## populate
This directory contains scripts and files used to populate the database with initial or test data.

## rosemary
This directory contains the code for the Rosemary CLI package. It is a version still under development and is not available in `pypi` at the moment.

## scripts
Contains auxiliary scripts that automate various tasks such as dependency installation, deployment, maintenance, and more.

## .env.example
This file provides an example of the environment variables needed to run the application. It is used as a reference for setting up the development environment.

## .flake8
Contains configurations for Flake8, a code style and checking tool for Python. It helps maintain code consistency and find common errors.

## .gitignore
A list of files and directories that Git should ignore. This prevents certain files (like local configurations and temporary files) from being included in version control.

## Dockerfile.dev
Docker file for building the application's development image. It includes all dependencies and configurations needed for a development environment.

## Dockerfile.mariadb
Docker file for building a MariaDB image, a SQL database. It is used to integrate the database into the development or production environment.

## Dockerfile.prod
Docker file for building the application's production image. It is optimized for performance and security.

## docker-compose.dev.yml
Docker Compose configuration file for the development environment. It defines how development containers should be orchestrated.

## docker-compose.prod.yml
Docker Compose configuration file for the production environment. It defines how containers should be orchestrated in production.

## requirements.txt
A list of Python dependencies needed for the project. Used by `pip` to install all required libraries.

## setup.py
A setup script used for distributing Python packages. It defines package properties such as name, version, and dependencies. En este caso, sirve para poder usar el paquete `rosemary`
