---
layout: default
title: BDD plugin
parent: Core and plugins
nav_order: 4
---

# BDD plugin
{: .no_toc }


The BDD model plugin provides the metaclases required to work with 
SAT models and to transform feature models into BDD.
{: .fs-6 .fw-300 }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

{: .highlight }
> Official repository
>
> ```
> https://www.github.com/flamapy/bdd_metamodel
> ```

## Description
This plugin supports Binary Decision Diagrams (BDDs) representations for feature models.

This is the architecture followed by this plugin:

![Architecture](https://raw.githubusercontent.com/flamapy/bdd_metamodel/master/doc/bdd_plugin.png)

The BDD plugin relies on the [dd](https://github.com/tulip-control/dd) library to manipulate BDDs.
The complete documentation of such library is available [here](https://github.com/tulip-control/dd/blob/main/doc.md).

The following is an example of feature model and its BDD using complemented arcs.

![FM Example](https://raw.githubusercontent.com/flamapy/bdd_metamodel/master/doc/fm_example.png)

![BDD Example](https://raw.githubusercontent.com/flamapy/bdd_metamodel/master/doc/bdd_example.svg)


# Objectives

The core plugin provides the following functionallity

1. Storage and manipulation of BDD
2. Read and store of BDD models
3. Implement operations that require a complex analysis
4. Transform feature models into BDD models

# Operations
Currently, this plugin enables the following operations. 

* Sampling
* Feature Inclusion Probability
* Product distribution
* List products
* Products number
* Uniform sampling

# Transformations supported
Currently this plugins enables a set of transformations for CNF and feaute models. Concretely we support:

|    Format/model   |  Model2Model | Model2Text  | Text2Model  |
| -----------       | ------------ | ----------- | ----------- |
| Feature model     | [x]          |             |             |
| BDD               |              |             |  [x]        |
