---
layout: default
title: Test users
parent: Installation
permalink: /docs/installation/test_users
nav_order: 4
---

# Test users

Test users are already available when the system is installed, regardless of the configuration environment. This is possible thanks to the `rosemary db:seed` command that is launched.

```
User: user1@example.com
Pass: 1234
```

```
User: user2@example.com
Pass: 1234
```

{: .important-title }
> <i class="fa-solid fa-database"></i> Repopulate the database
>
> You can change these test users and popular more modules. Visit [Seeders]({{site.baseurl}}/docs/rosemary/managing_database/seeders).
