---
layout: default
title: Installation with Vagrant
parent: Installation
permalink: /installation/installation_with_vagrant
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
> <i class="fa-solid fa-desktop"></i> Required Vagrant, Ansible and VirtualBox installation
>
> You need to have Vagrant, Ansible and VirtualBox installed on the machine where you want to deploy {% include uvlhub.html %}

{: .note-title }
> <i class="fa-solid fa-code"></i> Only for a development environment
>
> This manual is intended for a development environment. For a production environment, visit [Deployment]({{site.baseurl}}/deployment).

{: .warning-title }
> <i class="fa-solid fa-eye"></i> Be very careful!
>
>  Vagrant deployment is sensitive to permissions on previously set files and folders. To avoid problems
> when starting up the machine, it is recommended to delete the following files and folders (if they exist) in the root of the project:
>
> ```
> rm -r uploads
> rm -r rosemary.egg-info
> rm app.log*
> ```


## Set environment files

First, copy the `.env.vagrant.example` file to the `.env` file that will be used to set the environment variables.

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

{: .highlight }
If everything worked correctly, you should see the deployed version of {% include uvlhub.html %} in development at `http://localhost:5000`

### Accessing the VM

To access the VM and execute operations from within (such as `rosemary`), run:

```
vagrant ssh
```

This will switch to the internal MV console. To exit, run:

```
exit
```

### Provision the VM
To rerun the provisioning scripts (e.g., after changes), use:

#### If the VM is off:
```
vagrant up --provision
```

#### If the VM needs a restart:

```
vagrant reload --provision
```

### See VM status

To verify that the virtual machine is running correctly, use the following command:

```
vagrant status
```

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

The `.vagrant` folder is a directory automatically created by Vagrant at the same level as the Vagrantfile. It contains metadata and configurations necessary for Vagrant to manage the virtual machines associated with that project. It is convenient to delete this folder as well if we do not want to have previous configurations that conflict:

```
rm -r .vagrant
```

Following these steps, you should be able to set up, run, and manage your Vagrant virtual machine efficiently.