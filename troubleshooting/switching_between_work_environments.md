---
layout: default
title: Switching between work environments
parent: Troubleshooting
permalink: /troubleshooting/switching_between_work_environments
---

# Switching between work environments
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

## *bash: .../venv/bin/flask: /vagrant/venv/bin/python3.12: intérprete erróneo: No existe el archivo o el directorio*

When you switch working environment, for example, from local to Docker or Vagrant, you have to take into account that `venv` can be “hijacked” by the new environment. That is, it is Docker or Vagrant that creates its own `venv` folder. Given that there are bind mounts in these environments with respect to the host machine, it could be the case that when returning to the local environment, the `venv` folder is not originally ours.


### Solution 1: recreate the `venv` folder in local environment

```
rm -r venv
python3.12 -m venv venv
source venv/bin/activate
cp .env.local.example .env
pip install --upgrade pip
pip install -r requirements.txt
```

### Solution 2: use a name for the local environment different from the conventional one

When we are in local, we create a virtual environment named `myenv` for example:

```
python3.12 -m venv myenv
(other operations)
```

When returning to the local environment from Docker or Vagrant, the `myenv` folder will remain unchanged. This will avoid having to reinstall all the dependencies each time you return to the local environment.