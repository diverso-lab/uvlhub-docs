---
layout: default
title: Feature model plugin
parent: Core and plugins
nav_order: 2
---

# Feature model plugin
{: .no_toc }


The feature model plugin provides the metaclases required to work with feature models.
{: .fs-6 .fw-300 }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

{: .highlight }
> Official repository
>
> ```
> https://www.github.com/flamapy/fm_metamodel
> ```

## Description

One of the main parts of {% include flamapy.html %} is the feature model metamodel. This plugin provides:

1. The metaclasses required to store and manipulate cardinality-based feature models.
2. A transformation into the PySAT metamodel.
3. A set of model to text (M2T) and text to model (T2M) transformations to read and save feature model serializations.

This enables the reading and saving of feature models into XML and JSON files [22]; and,

4. A set of operations to extract information from the structural properties of the model, such as counting the number of features, the number of cross-tree constraints, the branching factor, etc.

## Objectives

The core plugin provides the following functionallity

1. Storage and manipulation of feature models
2. Read and store of feature models
3. Implement operations that do not rely on solvers backend

## Operations

Currently, this plugin enables the following operations. Note that these operations are executed without a backend solver which makes them scalable and fast while having some limitations:

* Atomic sets
* Average Branching factor
* Core Features
* Count leafs
* Estimated product number
* Feature ancestors
* Leaf features
* Max depth tree
* Average Branching factor


# Transformations supported

Currently this plugins enables a set of TextToModel transformations (a.k.a Parsers) and ModelToText transformations (a.k.a serializations) for the most common variability serializations found in the literatures. Concretely we support:

|    Format   |  Model2Text  |    Text2Model   |
| ----------- | ------------ | --------------- |
| AFM (Fama format)   | [x]  |        [x]      |
| Feature IDE |              |        [x]      |
| Glencoe     |     [x]      |        [x]      |
| Splot       |     [x]      |                 |
| UVL         |     [x]      |        [x]      |
| Fama XML    |              |        [x]      |
| Json        |     [x]      |                 |
