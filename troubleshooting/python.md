---
layout: default
title: Python
parent: Troubleshooting
permalink: /troubleshooting/python
---

# Python
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

{: .important-title }
> <i class="fa-brands fa-python"></i> The project targets Python 3.13
>
> The root `pyproject.toml` declares `requires-python = ">=3.13"`, the Docker images are built from
> `python:3.13-slim`, the Vagrant machine installs `python3.13`, and the CI workflows set up `3.13`. Anything older
> will fail to install the dependencies.

## *No module named '_ctypes'*

This is caused by an incorrect installation of Python. The best thing to do is to delete the current Python 3.13
version from the system, purge it and reinstall Python 3.13 from source, going through the build.

Compiling takes a few minutes, but it is effective.

### Remove the current version of Python 3.13 (if already installed)

It is important not to remove the default versions of Python that come with Ubuntu, as they are necessary for the
system to function properly. Be sure not to remove critical versions such as the distribution's own `python3`, which
may be part of the system. If you already installed Python 3.13 from external sources or a PPA and want to reinstall
it, you can remove it like this:

```bash
sudo apt remove --purge python3.13
sudo apt autoremove
```

### Install necessary dependencies

Before installing Python 3.13, make sure you have the necessary tools to compile Python from source:

```bash
sudo apt update
sudo apt install -y build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev xz-utils tk-dev libffi-dev liblzma-dev python3-openssl git
```

The package that fixes `No module named '_ctypes'` specifically is `libffi-dev`. It must be present *before* you
configure and build, otherwise the `_ctypes` extension module is silently skipped.

### Download Python 3.13 from source

Download Python 3.13 from the official Python archives:

```bash
wget https://www.python.org/ftp/python/3.13.14/Python-3.13.14.tgz
tar -xvf Python-3.13.14.tgz
```

Any `3.13.x` release works. Replace the version number in both the URL and the commands below if you prefer a
different patch release from [python.org/ftp/python](https://www.python.org/ftp/python/).

### Compile and install Python

```bash
cd Python-3.13.14
./configure --enable-optimizations
make -j$(nproc)
sudo make altinstall
```

Note: Use `altinstall` instead of `install` to avoid overwriting the default version of Python on your system.

### Verify the installation

After installation, verify that Python 3.13 is correctly installed by running:

```bash
python3.13 --version
```

And verify that the module that failed is now importable:

```bash
python3.13 -c "import ctypes; print('ok')"
```

### Recreate the virtual environment

A virtual environment created with the broken interpreter stays broken. Once Python 3.13 is rebuilt, throw it away
and start again:

```bash
rm -r venv
python3.13 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
pip install -e ./rosemary
```
