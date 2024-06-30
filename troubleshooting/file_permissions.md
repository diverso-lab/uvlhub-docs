---
layout: default
title: File permissions
parent: Troubleshooting
permalink: /troubleshooting/file_permissions
---

# File permissions
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

## *PermissionError: [Errno 13] Permission denied: '...app.log'*

There is a problem with file permissions. The simplest solution, from the console, is:

```
sudo rm app.log
```
