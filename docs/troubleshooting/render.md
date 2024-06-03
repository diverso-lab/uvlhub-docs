---
layout: default
title: Render
parent: Troubleshooting
permalink: /docs/troubleshooting/render
nav_order: 3
---

# Render
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

## *ERROR [flask_migrate] Error: Can't locate revision identified by*

This is due to a cache problem or a problem with the migration checking system.

### Delete migration in Filess.io database

A common error is often migrations. If you encounter the error `ERROR [flask_migrate] Error: Can't locate revision identified by...` it means that there has been a conflict with the Flask cache. It is very easy to solve it:
 - We go to the management panel of our Filess.io database.
 - Click on `Web Client`.
 - Click on the table `alembic_version`.
 - Identify the conflicting migration on the right, right click, `Delete rows (s)`.
 - To apply the changes, click on `Save` in the bottom menu.
 - This should now allow the normal deployment process. Render makes several attempts, but if it doesn't, click `Manual Deploy` and `Clear build cache & deploy`.

### Check that migrations are in a consistent state

If, after several continuous deployments, you still encounter the problem of migrations, perform these steps in your development environment:

1. **Check current migration state**: Use the Flask-Migrate command to show the current state of migrations. Run the following command in your terminal:

    ```sh
    flask db current
    ```

    This will show you the current migration version applied to your database.

2. **Compare migration deads**: Ensure that the migration head in your database matches the head of your migration scripts. Run the following command to show the head of your migrations:

    ```sh
    flask db heads
    ```

    If the heads do not match, there might be pending migrations that need to be applied.

3. **Apply pending migrations**: If there are pending migrations, apply them by running:

    ```sh
    flask db upgrade
    ```

    This command will apply any new migrations to bring your database schema up to date.

4. **Verify migration history**: To see the history of migrations applied, you can use the following command:

    ```sh
    flask db history
    ```

    This will display the list of all migrations applied in chronological order.

5. **Check for inconsistencies**: If you suspect inconsistencies, you can verify the integrity of your migrations by comparing the actual database schema with your migration scripts. Use the `flask db stamp` command to stamp the database with the correct version if necessary:

    ```sh
    flask db stamp head
    ```

    This command ensures that the migration version in your database matches the latest migration script.


