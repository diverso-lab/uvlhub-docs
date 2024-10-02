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

## *No module named '_ctypes'*

This is caused by an incorrect installation of Python. The best thing to do is to delete the current Python 3.12 version from the system, purge and reinstall Python 3.12 from source, going through the build.

Compiling takes a few minutes, but it is effective.

### Remove the current version of Python 3.12 (if already installed) 

It is important not to remove the default versions of Python that come with Ubuntu, as they are necessary for the system to function properly. Be sure not to remove critical versions such as Python 3.10, which may be part of the system. If you already installed Python 3.12 from external sources or a PPA and want to reinstall it, you can remove it like this:

```bash
sudo apt remove --purge python3.12
sudo apt autoremove
```

### Install necessary dependencies
Before installing Python 3.12, make sure you have the necessary tools to compile Python from source:

```bash
sudo apt update
sudo apt install -y build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev xz-utils tk-dev libffi-dev liblzma-dev python3-openssl git
```

### Download Python 3.12 from source

Download Python 3.12 from the official Python archives:

```bash
wget https://www.python.org/ftp/python/3.12.0/Python-3.12.0.tgz
tar -xvf Python-3.12.0.tgz
```

### Compile and install Python

```bash
cd Python-3.12.0
./configure --enable-optimizations
make -j$(nproc)
sudo make altinstall
```

Note: Use `altinstall` instead of `install` to avoid overwriting the default version of Python on your system.

### Verify the installation

After installation, verify that Python 3.12 is correctly installed by running:

```bash
python3.12 --version
```