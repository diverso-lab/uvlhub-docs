---
layout: default
parent: Testing
grand_parent: Rosemary CLI
title: Load tests
permalink: /rosemary/testing/load_tests
nav_order: 3
---

# Load tests
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

## Introduction to Locust

Locust is an open-source load testing tool. You describe user behaviour in Python and Locust swarms
your system with simulated users, reporting response times and failures as it goes. It is the top
level of the [testing pyramid]({{site.baseurl}}/rosemary/testing).

### Key features

- Scalability: capable of simulating very large numbers of concurrent users.
- Flexibility: user behaviour is plain Python.
- Real-time monitoring: live statistics and charts while the test runs.

### Ramp-up in Locust

Ramp-up is the gradual increase in the number of simulated users over a period. It lets you watch
how the system degrades as load builds, instead of hitting it with the full load at once.

---

## Where load tests live

One file per feature, at:

```
app/features/<feature>/tests/locustfile.py
```

These files are Locust scenarios, not pytest modules. They define `HttpUser` and `TaskSet`
subclasses and resolve the target host through the framework helper:

```python
from locust import HttpUser, TaskSet, between, task
from splent_framework.environment.host import get_host_for_locust_testing
```

{: .note-title }
> <i class="fa-solid fa-circle-info"></i> The `load` marker
>
> `pyproject.toml` declares a `load` marker alongside the other five levels
> (`load: locust load tests (run via 'rosemary locust')`). Because `locustfile.py` does not match
> `python_files = ["test_*.py"]` and carries no `pytestmark`, pytest never collects it, and no file
> in the repository actually applies `@pytest.mark.load`. The marker names the level; `rosemary
> locust` runs it. This is why `rosemary test --load` only prints a pointer to this command.

### Features without a locustfile

Not every feature ships one, and the omissions are deliberate:

| Feature | Why there is no locustfile |
|---|---|
| `webhook` | Its endpoint performs a real redeployment of the running containers. Putting concurrent traffic on it would repeatedly redeploy the environment. Even its integration tests replace `WebhookService.deploy` with a recorder. |
| `zenodo` | Its service is a client for the external Zenodo REST API. Load traffic here would hammer a third-party service rather than {% include uvlhub.html %}. Its service tests patch `requests` for the same reason. |
| `featuremodel` | Its own route renders an empty template. Feature models are only browsable through the dataset page, so that traffic is already covered by the `dataset` locustfile. |

The features that do ship one are `auth`, `dataset`, `explore`, `flamapy`, `hubfile`, `profile`,
`public` and `team`.

---

{: .important-title }
> <i class="fa-solid fa-terminal"></i> Using Locust with your development environment
>
> Load tests can be executed from any environment. To select the right one for the Rosemary CLI, see
> [Using Rosemary]({{site.baseurl}}/rosemary/using_rosemary).

## Load testing one feature

```
rosemary locust auth
```

Rosemary checks that `app/features/auth/` exists and that
`app/features/auth/tests/locustfile.py` exists. If either is missing it tells you the exact path it
looked for and stops.

### What happens inside Docker

Rosemary builds `docker/images/Dockerfile.locust`, then starts a container from it with three
things wired up for you:

- the repository mounted on `/workspace`, which is where the image sets `WORKDIR` and `PYTHONPATH`,
  so the `-f` path it passes resolves;
- the same Docker network as the running stack, read off `web_app_container` rather than assumed,
  so it keeps working whatever Compose project name you brought the stack up under;
- `WORKING_DIR=/workspace/`, which is what makes `get_host_for_locust_testing()` resolve to
  `http://nginx_web_server_container`. Without it the scenario would target
  `http://localhost:5000`, and inside the Locust container that is the Locust container itself.

> {: .highlight }
  **Locust is now serving its web interface at `http://localhost:8089`**

Open that page, set the number of users and the spawn rate, and start the run.

If you would rather drive Locust yourself, the equivalent manual invocation from the host is:

```bash
docker build -f docker/images/Dockerfile.locust -t locust-image .
```

```bash
docker run --rm -p 8089:8089 \
  -e WORKING_DIR=/workspace/ \
  -v "$PWD":/workspace \
  --network uvlhub_uvlhub_network \
  locust-image -f /workspace/app/features/auth/tests/locustfile.py
```

Confirm the network name against your own stack, since it carries the Compose project name:

```bash
docker network ls --format '{% raw %}{{.Name}}{% endraw %}' | grep uvlhub
```

### Running headless

To run without the web interface, which is what you want in a script, add `--headless` and a
duration:

```bash
docker exec web_app_container locust \
  -f app/features/auth/tests/locustfile.py \
  --headless -u 5 -r 1 -t 30s --only-summary
```

This runs Locust inside the app container rather than a separate one, so it needs no image build
and picks up `WORKING_DIR` from the environment already there.

## Running without a feature name

```
rosemary locust
```

{: .warning-title }
> <i class="fa-solid fa-triangle-exclamation"></i> This form does not work
>
> With no argument Rosemary defers to the default bootstrap that ships with `splent_framework`, and
> that bootstrap has not followed the `app/features/` rename. `splent_framework` 1.6.1 globs
> `app/modules/*/tests/locustfile.py`, a directory this repository does not have, so it collects
> zero `HttpUser` classes and raises at import time, before Locust starts:
>
> ```
> ValueError: No User class found!
> ```
>
> Reproduce it directly:
>
> ```bash
> docker exec web_app_container python -c "from splent_framework.bootstraps import locustfile_bootstrap"
> ```
>
> Name the feature.

The two environments reach that bootstrap by different routes. Locally and under Vagrant,
`run_in_console` in `rosemary/src/rosemary/commands/locust.py` imports it in-process, and the import
statement itself is what raises:

```python
from splent_framework.bootstraps import locustfile_bootstrap

locustfile_path = locustfile_bootstrap.__file__
```

In Docker, Rosemary never imports the bootstrap. It just omits `-f`, and
`docker/entrypoints/locust_entrypoint.sh` resolves the path with a shell `python -c`, which fails
the same way.

## How it runs per environment

`rosemary locust` branches on `WORKING_DIR`:

**Docker (`WORKING_DIR=/workspace/`)** — Rosemary builds `docker/images/Dockerfile.locust` into an
image called `locust-image` and starts a detached `locust_container` on port 8089. It reads the
volume and the network off the running `web_app_container` rather than assuming names, so it
survives a non-default Compose project name.

**Local (`WORKING_DIR` unset)** — Rosemary starts `locust -f <path>` as a background process. If a
`locust` process is already running it says so and does nothing.

**Vagrant (`WORKING_DIR=/vagrant/`)** — the same background process as local.

## Stopping Locust

You need to stop Locust before you can start a run for a different feature, and after you edit a
`locustfile.py`:

```
rosemary locust:stop
```

`locust:stop` targets the container Rosemary named. The manual `docker run` shown earlier runs in
the foreground with `--rm`, so stop that one with Ctrl-C instead.

In Docker this runs `docker stop locust_container` followed by `docker rm locust_container`. Locally
and under Vagrant it sends `SIGTERM` to the running `locust` process.

## Official documentation

We recommend Locust's [official documentation](https://docs.locust.io/en/stable/writing-a-locustfile.html)
for designing further tests against {% include uvlhub.html %}
