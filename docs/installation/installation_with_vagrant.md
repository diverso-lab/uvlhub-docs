---
layout: default
title: Installation with Vagrant
parent: Installation
permalink: /docs/installation/installation_with_vagrant
nav_order: 3
---

# Installation with Vagrant
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

{: .important-title }
> <i class="fa-solid fa-desktop"></i> Required Vagrant and VirtualBox installation
>
> You need to have Vagrant and VirtualBox installed on the machine where you want to deploy {% include uvlhub.html %}

{: .note-title }
> <i class="fa-solid fa-code"></i> Only for a development environment
>
> This manual is intended for a development environment. For a production environment, visit 'Deployment.

## Set environment files

First, copy the .env.vagrant.example file to the .env file that will be used to set the environment variables.

```
cp .env.vagrant.example .env
```

## Working with Vagrant

{: .warning-title }
> <i class="fa-solid fa-folder"></i> `vagrant` folder
>
> All Vagrant commands must be executed inside the `vagrant` folder located in the root of the project.
>
> ```
> cd vagrant
> ```



### Run the VM

To start the virtual machine in development mode, use the Vagrantfile located in `vagrant` folder. The command will set up and run the VM.

```
vagrant up
```

### Provision the VM

If you need to run the provisioning scripts again (`*.yml`) (e.g., after making changes to them), use the following command:

```
vagrant up --provision
```

### See VM status

To verify that the virtual machine is running correctly, use the following command:

```
vagrant status
```

{: .highlight }
If everything worked correctly, you should see the deployed version of {% include uvlhub.html %} in development at `http://localhost:5000`

### Halt the VM

To halt (stop) the virtual machine, use the following command:

```
vagrant halt
```

### Destroy the VM

To destroy the virtual machine (removing all data), use the following command:

```
vagrant destroy
```

Following these steps, you should be able to set up, run, and manage your Vagrant virtual machine efficiently.