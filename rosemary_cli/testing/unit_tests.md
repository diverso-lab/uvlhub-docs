---
layout: default
parent: Testing
grand_parent: Rosemary CLI
title: Unit tests
permalink: /rosemary/testing/unit_tests
nav_order: 1
---

# Unit tests
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}


## Testing all modules

To run tests across all modules in the project, you can use the following command:

```
rosemary test
```

This command will execute all tests found within the `app/modules` directory, covering all the modules of the project.

## Testing a specific module

If you're focusing on a particular module and want to run tests only for that module, you can specify the module
name as an argument:

```
rosemary test <module_name>
```

## Testing with an expression

To run tests that match a specific expression:

```
rosemary test -k <expression>
```

To run tests for a specific module that match a specific expression:

```
rosemary test <module_name> -k <expression>
```