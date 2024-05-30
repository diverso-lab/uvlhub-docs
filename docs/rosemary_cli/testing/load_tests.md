---
layout: default
parent: Testing
grand_parent: Rosemary CLI
title: Load tests
permalink: /docs/rosemary/testing/load_tests
nav_order: 3
---

# Load tests
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

## Introduction to Locust

Locust is an open-source load testing tool that allows you to define user behavior with Python code and swarm your system with millions of simultaneous users. It’s useful for testing the performance of web applications and identifying potential bottlenecks.

### Key Features:

- Scalability: Capable of simulating millions of users.
- Flexibility: User behavior can be defined with simple Python code.
- Real-time Monitoring: Provides real-time statistics and metrics during the test.

### Ramp-Up in Locust

Ramp-up refers to the gradual increase in the number of simulated users over a specified period. This approach helps in observing how the system behaves as the load increases incrementally, rather than being hit with the maximum load all at once.

---

{: .important-title }
> <i class="fa-solid fa-terminal"></i> Using Locust with your development environment
>
> Load tests can be executed from any environment. To use the appropriate environment with Rosemary CLI, visit [Using Rosemary]({{site.baseurl}}/docs/rosemary/using_rosemary).

## Run all load tests

To execute all load tests for all modules, run the following command:

```
rosemary locust
```

> {: .highlight }
  **If everything worked correctly, you should see a Locust interface at `http://localhost:8089`**

## Run load tests from specific module

It's possible to run the load tests for a specific module. For this, the module must have a `locustfile.py` file defined within it. To execute the load tests for that module, run:

```
rosemary locust <module_name>
```

Replace `<module_name>` with the name of the module.

## Stop Locust

Es necesario detener Locust si se se desean correr los test de un módulo concreto o si se ha modificado el `locustfile.py` de algún módulo. Para detener Locust, ejecutar:

```
rosemary locust:stop
```


## Official documentation

We recommend visiting Locust's [official documentation](https://docs.locust.io/en/stable/writing-a-locustfile.html) for further test design to check the performance of {% include uvlhub.html %}