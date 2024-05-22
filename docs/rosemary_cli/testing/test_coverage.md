---
layout: default
parent: Testing
grand_parent: Rosemary CLI
title: Test coverage
permalink: /docs/rosemary/testing/test_coverage
nav_order: 2
---

# Test coverage
{: .no_toc }

The `rosemary coverage` command facilitates running code coverage analysis for your Flask project using `pytest-cov`. 
This command simplifies the process of assessing test coverage.

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

## Test coverage of all modules

To run coverage analysis for all modules within the `app/blueprints` directory and generate an HTML report, use:

```
rosemary coverage
```

## Test coverage of a specific module

If you wish to run coverage analysis for a specific module, include the 
module name:

```
rosemary coverage <module_name> 
```

## Command Options

### **\--html**

This option generates an HTML coverage report. The report is saved in the `htmlcov` directory
at the root of your project.

```
rosemary coverage --html
```
