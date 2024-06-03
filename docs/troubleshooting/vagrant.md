---
layout: default
title: Vagrant
parent: Troubleshooting
permalink: /docs/troubleshooting/vagrant
---

# Vagrant
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

## *A Vagrant environment or target machine is required to run this command. Run ⁠ vagrant init ⁠ to create a new Vagrant environment. Or,get an ID of a target machine from ⁠ vagrant global-status ⁠ to run this command on. A final option is to change to a directory with a Vagrantfile and to try again*

You are not in the `vagrant` folder.

```
cd vagrant
```

## *Vagrant cannot forward the specified ports on this VM, since they would collide with some other application that is already listening on these ports. The forwarded port to 8089 is already in use on the host machine.*

Locust is most likely running locally and you need to shut it down. To do this, run it from the local environment:

```
rosemary locust:stop
```