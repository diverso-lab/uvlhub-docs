---
layout: default
title: Test users
parent: Installation
permalink: /installation/test_users
nav_order: 4
---

# Test users

Test users are already available in every development installation, whether it was done with Docker, with
Vagrant or manually. This is possible thanks to the `rosemary db:seed` command that is launched. Production
deployments are the exception: their entrypoints never seed, so these accounts do not exist there.

```
User: user1@example.com
Pass: 1234
```

```
User: user2@example.com
Pass: 1234
```

Both users are created by the seeder in `app/features/auth/seeders.py`, which also creates a profile for each
one: John Doe for the first user and Jane Doe for the second.

## When seeding happens

With Docker and with Vagrant you get these users for free, because the provisioning runs the seeders for you:

- the development entrypoint runs `rosemary db:seed -y` the first time the database comes up empty,
- the Vagrant playbook runs `rosemary db:seed -y --reset`.

After a manual installation you run it yourself, once the migrations have been applied:

```
rosemary db:seed
```

This needs the project root on the import path, exactly as described in
[Manual installation]({{site.baseurl}}/installation/manual_installation). If `rosemary db:seed` fails with
`ModuleNotFoundError: No module named 'app'`, run `export PYTHONPATH=$(pwd)` from the root of the repository
and try again.

You can also seed a single feature by passing its name:

```
rosemary db:seed auth
```

{: .important-title }
> <i class="fa-solid fa-database"></i> Repopulate the database
>
> You can change these test users and populate more features. Visit [Seeders]({{site.baseurl}}/rosemary/managing_database/seeders).
