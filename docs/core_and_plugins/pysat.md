---
layout: default
title: PySAT plugin
parent: Core and plugins
nav_order: 3
---

# PySAT plugin
{: .no_toc }


The pysat model plugin provides the metaclases required to work with SAT models and to transform feature models into SAT.
{: .fs-6 .fw-300 }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

{: .highlight }
> Official repository
>
> ```
> https://www.github.com/flamapy/pysat_metamodel
> ```

## Description

This plugin implements the classes to perform AAFM using the [PySAT](https://pysathq.github.io/) metasolver. It encompasses the set of variables and constraints objects to execute the analysis operations using PySAT as the backend. This allows us to rely on more than ten SAT solvers. This plugin offers the following functionality:

1. The metaclasses required to run the SAT instance representing our feature models.
2. A set of operations to extract information from the models.
3. A set of model to text (M2T) transformations to save the CNF representation of the current SAT instance.


## Objectives

The core plugin provides the following functionallity:

1. Storage and manipulation of SAT
2. Read and store of SAT models
3. Implement operations that require a complex analysis
4. Transform feature models into SAT models

## Operations

Currently, this plugin enables the following operations: 

* Commonality
* Core Features
* Dead features detection
* Error detection
* False optional detection
* Filter
* List products
* Products number
* Valid
* Valid product (full configuration)
* Valid configuration (partial configuration)


## Transformations supported

Currently this plugins enables a set of transformations for CNF and feaute models. Concretely we support:

|    Format/model   |  Model2Model | Model2Text  | Text2Model  |
| -----------       | ------------ | ----------- | ----------- |
| Feature model     | [x]          |             |             |
| CNF               |              |             |  [x]        |
