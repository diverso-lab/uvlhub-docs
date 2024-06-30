---
layout: default
parent: Managing database
grand_parent: Rosemary CLI
title: Migrations
permalink: /rosemary/managing_database/migrations
nav_order: 1
---

# Migrations
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

If during development there are new changes in the model, run:

```
rosemary db:migrate
```

This command will detect all changes in the model (new tables, modified fields, etc.) and apply those changes to the database.