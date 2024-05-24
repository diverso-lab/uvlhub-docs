---
layout: default
title: SSL certificate
parent: Deployment
permalink: /docs/deployment/ssl_certificate
nav_order: 3
---

# SSL certificate
{: .no_toc }

An SSL certificate (https) is essential for securing the communication between a website and its users. It encrypts transmitted data, protecting sensitive information from interception. Additionally, it authenticates the website's identity, ensuring users they are interacting with the legitimate site. SSL certificates also improve search engine rankings, enhancing the website's visibility and credibility.

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

{: .important }
The use of SSL certificates is configured for Docker deployment only. Visit '[Installation with Docker]({{site.baseurl}}/docs/installation/installation_with_docker).

## Scripts folder

To begin with, we must go to the `scripts` folder:

```
cd scripts
```

## Generate certificate

To generate a new certificate, run: 

```
chmod +x ssl_setup.sh
./ssl_setup.sh
```

## Renew certificate

To renew a certificate that is less than 60 days from expiry, execute:

```
chmod +x ssl_renew.sh
./ssl_renew.sh
```
