---
layout: default
title: HTTP Request
parent: Architecture
permalink: /architecture/http_request
nav_order: 3
---

# HTTP Request
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

![HTTP Request](/assets/images/http_request.svg)
*Figure 1: HTTP Request.*


The Figure 1 shows an HTTP request in {% include uvlhub.html %} using the Flask framework, organizing the code in a Model-View-Controller (MVC) pattern.


## Internet

The application is accessible through the internet.

## Server

A Flask server handles web requests and responses.

## Model-View-Controller (MVC)

Each module in {% include uvlhub.html %} has a series of folders and files to handle HTTP requests separating responsibility as indicated:

- *Model*. Represents the data and business logic of the application.
    - `models.py`: Defines the data structures and database interactions.
    - `repositories.py`: Implements functions to access and manipulate the data stored in the models.
- *View*. Represents the user interface.
    - `templates`: Contains the Jinja templates to generate the user interface.
    - `forms.py`: Defines forms and data validations that users can submit.
- *Controller*. Handles the application logic and the communication between the model and the view.
    - `routes.py`: Defines the application routes, handling HTTP requests and determining which view should be rendered.
    - `services.py`: Implements the business logic and operations that belong neither to the model nor to the view.

## Interaction and Data Flow

- Requests come to the Flask server from the Internet.
- The server redirects these requests to `routes.py`.
- `routes.py` can call `services.py` to perform business operations.
- `services.py` interacts with repositories.py to access data from `models.py` and the database.
- `forms.py` and templates are used to handle user input and generate the visual response that is sent back to the user through the Flask server.

## Database

- The database stores the persistent information of the application.
- `models.py` defines how this information is structured and accessed.

This architecture facilitates the separation of concerns, making the code more modular and easier to maintain. Each component has a clear and distinct responsibility, which improves the organization and scalability of the application.
