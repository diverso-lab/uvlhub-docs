---
layout: default
title: BDD (Colosal FM) plugin 
parent: Lab plugins
grand_parent: Core and plugins
nav_order: 5
---

# BDD (Colosal FM) plugin 
{: .no_toc }


The BDD model plugin provides the metaclases required to work with 
colosal feature models and transform them to BDD.
{: .fs-6 .fw-300 }

However, this implementation relies on the optimizations performed in the paper by Ruben Heradio, David Fernández-Amorós, José A. Galindo, David Benavides, and Don S. Batory: "Uniform and scalable sampling of highly configurable systems" (*Empirical Software Engineering*, 27(2): 44, 2022), which enables better scalability of the analysis.


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

## Objectives

The core plugin provides the following functionallity

1. Increase scalability for colosal feature models

## Operations

Currently, this plugin enables the following operations. 

* Sampling
* Feature Inclusion Probability
* Product distribution


## Transformations supported

Currently this plugins enables a set of transformations for CNF and feaute models. Concretely we support:

|    Format/model   |  Model2Model | Model2Text  | Text2Model  |
| -----------       | ------------ | ----------- | ----------- |
| Feature model     | [x]          |             |             |
| DDDMP               |              |     [x]        |  [x]        |
| SPLX | | | [x]|
