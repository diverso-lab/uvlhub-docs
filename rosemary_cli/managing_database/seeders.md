---
layout: default
parent: Managing database
grand_parent: Rosemary CLI
title: Seeders
permalink: /rosemary/managing_database/seeders
nav_order: 1
---

# Seeders
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

## Basic Usage

It is possible to populate the database with predefined test data. It is very useful for testing features that
require existing data.

`db:seed` walks `app/features/`, imports every `seeders.py` it finds, collects every class that subclasses
`BaseSeeder` and calls `run()` on each of them.

### Populate from all features

To populate all test data of all features, run:

```
rosemary db:seed
```

### Populate from specific feature

If you only want to populate the test data of a specific feature, run:

```
rosemary db:seed <feature_name>
```

Replace `<feature_name>` with the name of the feature you want to populate (for example, `auth` for the
authentication feature).

## Execution order

Seeders often depend on each other. `DataSetSeeder`, for example, looks up the users that `AuthSeeder` inserts and
raises `Users not found. Please seed users first.` if they are not there yet.

Ordering is controlled by a `priority` class attribute, and seeders run from lowest value to highest:

```python
from splent_framework.seeders.BaseSeeder import BaseSeeder


class AuthSeeder(BaseSeeder):

    priority = 1  # runs before anything with a higher value

    def run(self):
        ...
```

`BaseSeeder` does not declare `priority` itself, so it is opt-in: a seeder that does not define one is treated as
`priority = 0` and therefore runs in the first group. Within the same priority value the order is not defined, so
give any seeder that depends on another one a strictly higher number.

In this repository `AuthSeeder` uses `priority = 1` and `DataSetSeeder` uses `priority = 2`.

## Writing a seeder

`BaseSeeder.run()` is abstract, so every seeder must implement it. Insert rows through `self.seed()`, which commits
the objects and returns them with their IDs populated:

```python
class ExampleSeeder(BaseSeeder):

    priority = 3

    def run(self):
        users = [
            User(email="user1@example.com", password="1234"),
            User(email="user2@example.com", password="1234"),
        ]
        seeded_users = self.seed(users)
        return seeded_users
```

All the objects passed in a single `self.seed()` call must be instances of the same model. On an integrity error the
session is rolled back and a `SeederError` is raised.

If one seeder fails, `db:seed` reports the error, stops, and does not run the remaining seeders.

## Reset database before populating

If you want to make sure that the database is in a clean state before populating it with test data, you can use the
`--reset` flag. This resets the database before running the seeders:

### Reset all features test data

```
rosemary db:seed --reset
```

You will be asked to confirm. Add `-y` (or `--yes`) to skip the prompt, which is what you want in a script:

```
rosemary db:seed --reset -y
```

The flag only has an effect together with `--reset`; without it there is no prompt to skip. The development
entrypoint uses the plain form, `rosemary db:seed -y`, right after migrating an empty database.

{: .warning-title }
> <i class="fa-solid fa-triangle-exclamation"></i> `--reset` also clears the uploads
>
> The reset it performs deletes the data in every table and then invokes `clear:uploads`, which empties the
> `uploads` folder. It does not delete the migrations.

### Reset test data of specific feature

You can also combine the `--reset` flag with a feature name if you want to reset the database before populating only
the test data of a specific feature:

```
rosemary db:seed <feature_name> --reset
```

Note that the reset always clears the whole database, not just the tables of that feature.
