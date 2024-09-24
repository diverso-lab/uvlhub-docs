---
layout: default
title: Deployment in Render
parent: Deployment
permalink: /deployment/render
nav_order: 2
---

# Deployment in Render
{: .no_toc }

[Render.com](https://render.com) is a modern hosting and deployment platform that simplifies the deployment of web applications and services. It provides a managed infrastructure that allows developers to focus on code instead of worrying about server configuration and maintenance. With Render, web applications, APIs, databases and static services can be deployed with ease. The platform supports multiple programming languages and frameworks, and provides advanced features such as integrated CI/CD, automatic scaling, and free SSL. In addition, Render offers an intuitive interface and extensive documentation, making the deployment process fast and accessible for beginners and experienced developers alike.

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---


## Part one: deploying database in Filess.io

{: .important-title }
> <i class="fa-solid fa-database"></i> External database
>
> Unfortunately, Render only has native support for PostgreSQL. All other databases (MySQL, MariaDB, etc), require a subscription fee. We use the Filess.io service to host the database.

We deploy the database service in [Filess.io](https://filess.io)

- Log in to Filess.io and create an account at [Sign up](https://dash.filess.io/#/register)
- Click on `+ New Database`.
- In `Database identifier`, we put `uvlhubdatabase`.
- In `Database engine`, we choose `MariaDB`.

This will take us to the main management section of our cloud database. It is important to keep this data in view, as we will need it in the next part.

---

## Part two: deploy application in Render

We are going to use Render as a cloud deployment service. 

### Sign in to Render

Click [Sign in](https://dashboard.render.com/). It is convenient that we use our GitHub account because it will be easier to link the repository where we are working.

### Create app instance

Since our app requires a specific configuration (install dependencies, scripts, create migrations, among others) we have our own Dockerfile image for the Render service.

#### **Basic Settings**

- In the top menu, click on `Dashboard` -> `New` -> `Web Service`.
- In Git Provider, we paste the path to the Git repository we want to deploy. Click on `Connect`.
- As `Name` we put `uvlhub_<uvus>`. For example, for the UVUS `drorganvidez`, the service name would be `uvlhub_drorganvidez`.
- In `Project` we can create a new project named `uvlhub` (this step is not very relevant).
- In `Language`, we will use `Docker` as the deployment system.
- In `Region` we choose `Frankfurt (central EU)`.
- Under `Branch`, unless we have a reason to do so, it should be `main`.
- In `Dockerfile Path` we make sure to put `docker/images/Dockerfile.render`
- In `Instance Type`, we choose `Free`.

#### **Environment Variables Configuration**.

In `Environment Variables`, to avoid defining each environment variable one by one, click on `Add from .env` and copy and paste this:

```
FLASK_APP_NAME="UVLHUB.IO"
FLASK_ENV=production
FLASK_APP=app
SECRET_KEY=dev_test_key_1234567890abcdefghijklmnopqrstu
DOMAIN=uvlhub_<uvus>.onrender.com
MARIADB_HOSTNAME=<CHANGE_THIS>
MARIADB_DATABASE=<CHANGE_THIS>
MARIADB_USER=<CHANGE_THIS>
MARIADB_PORT=<CHANGE_THIS>
MARIADB_PASSWORD=<CHANGE_THIS>
MARIADB_ROOT_PASSWORD=<CHANGE_THIS>
WORKING_DIR=/app/
```

> {: .highlight }
> <i class="fa-solid fa-seedling"></i> It is very important to replace the `<CHANGE_THIS>` values with the data provided by our database management panel in Filess.io.

> {: .highlight }
> <i class="fa-solid fa-seedling"></i> It is very important to replace the `<uvus>` values with your UVUS (University of Seville)

{: .important-title }
> <i class="fa-solid fa-triangle-exclamation"></i> Don't forget your own variables!
>
> If you have been using modules that included their own `.env` file, please note that in production environment neither the Rosemary CLI nor the `rosemary compose:env` command is available for security reasons.
> 
> That means that you have to add to the `Add from .env` option the variables defined by your modules.

### Verify deployment process

Once you have done the above steps, you should see a log. It is important to keep an eye out for any errors that may occur.

> {: .highlight }
> <i class="fa-solid fa-globe"></i> If everything went well, you should see our project deployed at `https://uvlhub_<uvus>.onrender.com`
> The deployment process can take up to 5 minutes.
