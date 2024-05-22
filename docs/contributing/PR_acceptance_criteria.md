---
layout: default
title: PR Acceptance criteria
parent: Contributing
grand_parent: Developing
permalink: /docs/developing/contributing/PR_acceptance_criteria
nav_order: 4
---

# PR Acceptance criteria
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

## Mandatory conditions

* Your code must work and provide a solution to its correspondent issues.
* **pytest** command must return no errors.
* Code quality commands **prospector** and **mypy flamapy** must return no messages.

## Recommendations and good practices

These practices are not mandatory, but consider that highly messy contributions can be rejected. They also make it easier for maintainers to revise your requests, allowing them to give you feedback instead of just rejecting your contribution.

## Descriptive pull requests

* Keep your commits [atomic](#atomic-commits) and [descriptive](#descriptive-commit-messages).
* You PR should end up looking like a history of concurrent descriptive commits that add up functionality until the issue is resolved.

## Clean code

* Modularize your code with descriptive function names.
* Comment your code, but do not overdo it.
* Keep your lines short and readable.
* Use descriptive variable names.

## Testing

* You should include functional testing to newly implemented features.