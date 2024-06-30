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
> Unfortunately, Render only has native support for PostgreSQL. All other databases (MySQL, MariaDB, etc), require a subscription. We use the Filess.io service to host the database.

We deploy the database service in [Filess.io](filess.io)

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

- In the top menu, click on `Dashboard` and then on the `New Web Service` button.
- Choose the option `Build and deploy from a Git repository`.
- We need to find the repository where we are working. Click on the `Connect` button.
    - As `Name` we put `uvlhub_web_app` or similar, any available name is fine.
    - In `Region` we choose `Frankfurt (central EU)`.
    - Under `Branch`, unless we have a reason to do so, it should be `main`.
    - Under `Root Directory`, we leave it blank.
    - In `Runtime`, we choose `Docker`.
    - In `Instance Type`, we choose `Free`.

#### **Environment Variables Configuration**.

In `Environment Variables`, to avoid defining each environment variable one by one, click on `Add from .env` and copy and paste this:

```
FLASK_APP_NAME="UVLHUB.IO"
FLASK_ENV=production
DOMAIN=render.com
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

{: .important-title }
> <i class="fa-solid fa-triangle-exclamation"></i> Don't forget your own variables!
>
> If you have been using modules that included their own `.env` file, please note that in production environment neither the Rosemary CLI nor the `rosemary compose:env` command is available for security reasons.
> 
> That means that you have to add to the `Add from .env` option the variables defined by your modules.

#### **Custom Dockerfile**

Now let's tell Render to use our custom Dockerfile

- We click on `Advanced`:
    - In `Dockerfile Path` we make sure to put `docker/images/Dockerfile.render`
    - The rest of the options are left untouched.
- Click on `Apply`.

### Verify deployment process

Once you have done the above steps, you should see a log. It is important to keep an eye out for any errors that may occur.

> {: .highlight }
> <i class="fa-solid fa-globe"></i> If everything went well, you should see our project deployed at `https://<name_of_my_app>.onrender.com/`
> The deployment process can take up to 5 minutes.

{: .warning-title }
> <i class="fa-solid fa-seedling"></i> Migrations troubleshooting
>
> A common error is often migrations. If you encounter the error `ERROR [flask_migrate] Error: Can't locate revision identified by...` it means that there has been a conflict with the Flask cache. It is very easy to solve it:
> - We go to the management panel of our Filess.io database.
> - Click on `Web Client`.
> - Click on the table `alembic_version`.
> - Identify the conflicting migration on the right, right click, `Delete rows (s)`.
> - To apply the changes, click on `Save` in the bottom menu.
> - This should now allow the normal deployment process. Render makes several attempts, but if it doesn't, click `Manual Deploy` and `Clear build cache & deploy`.