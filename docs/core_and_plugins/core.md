---
layout: default
title: Core
parent: Core and plugins
nav_order: 1
---

# Core
{: .no_toc }


The core component is the main entry point of {% include flamapy.html %}.
{: .fs-6 .fw-300 }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

{: .highlight }
> Official repository
>
> ```
> https://www.github.com/flamapy/core
> ```

## Description

The core component of {% include flamapy.html %} has three primary purposes:

1. **To provide a set of interfaces that serve as communicating components between the different plugins and the core.**
2. **To orchestrate the different plugins available in a Python installation.**
3. **To help developers to create new plugins.**

To fulfill the first purpose, it provides interfaces for the different transformations we can define. These are:

- **Model to Text (M2T)**
- **Text to Model (T2M)**
- **Model to Model (M2M)**

These transformations allow the reading and saving of model serializations as well as the implementation of translation between variability models and solvers, which are both treated as metamodels in this architecture. Additionally, it provides a set of common interfaces for operations over feature models.

## Objectives

The core plugin provides the following functionality:

- **Orchestrating the execution by providing a common interface with the end user.** Currently, three interfaces are offered:
  - As a command line utility
  - As a Python library to be embedded in your project
  - As a REST API to be consumed
- **Help with the creation of skeletons for future plugins.** To increase the number of plugins and ease their creation, the core plugin offers commands to generate empty plugins to be implemented.
- **Offers a set of interfaces (yes, interfaces in Python) for automated analysis operations to be implemented.**
