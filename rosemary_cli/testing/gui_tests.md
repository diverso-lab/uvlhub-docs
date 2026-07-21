---
layout: default
parent: Testing
grand_parent: Rosemary CLI
title: GUI tests
permalink: /rosemary/testing/gui_tests
nav_order: 4
---

# GUI tests
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

## Introduction to Selenium

Selenium is a suite of web browser automation tools. It provides an easy-to-use interface for
driving browsers such as Chrome and Firefox, which is what the `e2e` level of the
[testing pyramid]({{site.baseurl}}/rosemary/testing) uses to exercise the real interface.

{: .warning-title }
> <i class="fa-solid fa-triangle-exclamation"></i> VERY IMPORTANT!
>
> The application must be running before you start any Selenium test. These tests drive a live
> browser against a live server; nothing is stubbed.

E2E tests run against the **seeded development database**, not the test database that the other
levels use. They are written to be read-only for that reason: the development database is shared
and is not reset between runs.

---

## Where the tests live

One file per feature, at:

```
app/features/<feature>/tests/test_selenium.py
```

It is a file, not a directory. Features that ship one today are `auth`, `dataset`, `explore`,
`featuremodel`, `profile`, `public`, `team` and `zenodo`.

Each file declares the level once, at module scope:

```python
import pytest

from tests.selenium_support import close_driver, get_host_for_selenium_testing, initialize_driver

pytestmark = pytest.mark.e2e
```

That `pytestmark = pytest.mark.e2e` is what keeps browser tests out of a default `rosemary test`
run and what makes `--e2e` able to select them.

## The driver helpers

The imports come from `tests/selenium_support.py`, which since `splent_framework` 1.7.1 is a thin
wrapper over the framework's own helpers. The framework drives the grid natively: when
`SELENIUM_GRID_URL` is set, `initialize_driver` attaches to that hub through `webdriver.Remote`, so
the browser runs in the `selenium-chrome` or `selenium-firefox` container; without it, a local
browser is launched through `webdriver_manager`. `get_host_for_selenium_testing` honours
`SELENIUM_TARGET_URL`, which matters because the URL is resolved **by the browser**, and inside a
grid node `localhost` is the node itself.

What the wrapper adds on top:

```python
if os.getenv("WORKING_DIR", "") == "/workspace/":
    os.environ.setdefault("SELENIUM_GRID_URL", "http://selenium_hub_container:4444")
    os.environ.setdefault("SELENIUM_TARGET_URL", "http://nginx_web_server_container")
```

so the grid and the target default to this stack's container names under Docker, plus a pinned
1920x1080 window. Browser defaults differ (chrome nodes open at about 945px, firefox at about
1280px), and below the responsive breakpoint the sidebar collapses off-canvas, so an unpinned
viewport makes the same test pass on one browser and fail on the other.

Outside Docker neither variable is defaulted, so the framework launches a local browser against
`http://localhost:5000` and the identical test file works in both environments.

---

## Running interface tests

There are two ways in. They select the same tests, but they do not default to the same browser.

Through the normal test runner, selecting the `e2e` level:

```bash
rosemary test auth --e2e
```

Or through the dedicated command, which also lets you pick the browser:

```bash
rosemary selenium auth
```

Without a feature name, `rosemary selenium` collects every `test_selenium.py` it can find under
`app/features/` and runs them all:

```bash
rosemary selenium
```

`rosemary selenium` defaults to firefox. Override it with `--driver`:

```bash
rosemary selenium auth --driver chrome
```

The flag accepts only `firefox` and `chrome`, and it is exported as `SELENIUM_BROWSER`, which is
what `initialize_driver` reads.

`rosemary test --e2e` has no such flag and never sets `SELENIUM_BROWSER`. With the variable unset,
`tests/selenium_support.py` falls back to chrome:

```python
browser = (browser or os.getenv("SELENIUM_BROWSER") or "chrome").lower()
```

So the two entry points differ: `rosemary selenium` gives you firefox, `rosemary test --e2e` gives
you chrome. Export `SELENIUM_BROWSER=firefox` yourself if you want firefox from `rosemary test`.

Under the hood `rosemary selenium` runs pytest with the marker and the collected file paths:

```
pytest -v -m e2e /workspace/app/features/auth/tests/test_selenium.py
```

The paths carry the `$WORKING_DIR` prefix inside a container; outside Docker they start at
`app/features/`.

If you name a feature that has no `test_selenium.py`, the command tells you the exact path it
looked for and stops.

## Local environment

Outside Docker (`WORKING_DIR` unset), Selenium drives your own browser through your local drivers,
and the tests target `http://localhost:5000`.

{: .note-title }
> <i class="fa-solid fa-circle-info"></i> **Note for Ubuntu users**
>
> On Ubuntu 22.04 or newer you do not need to install anything. Firefox and GeckoDriver come
> preinstalled and ready for Selenium.

Otherwise install a browser and a driver. On Ubuntu the default archive carries `firefox` and
`chromium-chromedriver`:

```bash
sudo apt install firefox
# or, for the Chrome path
sudo apt install chromium-chromedriver
```

There is no `geckodriver` package and no `google-chrome-stable` package in the default archive, and
`chromedriver` has no installation candidate; asking for any of those gives you
`E: Unable to locate package`. If you need those specific builds, take them from the
[geckodriver releases](https://github.com/mozilla/geckodriver/releases),
[Chrome for Testing](https://googlechromelabs.github.io/chrome-for-testing/) and Google's own APT
repository.

Then run:

```bash
rosemary selenium auth --driver firefox
```

A real browser window opens on your desktop and executes the test.

## Docker environment (Selenium Grid)

Inside Docker (`WORKING_DIR=/workspace/`), Rosemary connects to the Selenium Grid defined in
`docker/docker-compose.dev.yml`. Three services make it up:

- `selenium-hub` — the grid hub, container `selenium_hub_container`, port 4444
- `selenium-chrome` — a Chrome node, container `selenium_chrome_container`
- `selenium-firefox` — a Firefox node, container `selenium_firefox_container`

Launch the grid:

```bash
docker compose -f docker/docker-compose.dev.yml up -d selenium-hub selenium-chrome selenium-firefox
```

The `web` service already declares `selenium-hub` as a dependency, so bringing the whole
development stack up starts the hub for you as well.

Check that the grid is ready:

```bash
curl http://localhost:4444/status | jq .
```

Look for `"ready": true` in the response:

```
{
  "value": {
    "message": "Selenium Grid ready.",
    "ready": true,
    "nodes": [ ... ]
  }
}
```

That is an excerpt. The full body also lists every registered node with its slots and stereotypes,
so expect a much larger object.

Then run the tests from inside `web_app_container`:

```bash
rosemary selenium auth --driver chrome
```

The browser runs inside the Chrome or Firefox container and drives the app through nginx.

### Viewing the browser in Docker (VNC)

**VNC** (Virtual Network Computing) is a remote-desktop protocol that lets you see and control a
graphical session running on another machine or container over the network.

In our setup, each Selenium browser node runs its own virtual display inside Docker and exposes it
over VNC, so you can watch the test in real time even though the browser window is not on your host
desktop.

### Connect via VNC

You can connect to the running browsers with any VNC viewer. Each node exposes its own port:

| **Browser** | **VNC URL**              | **Default password**         |
|--------------|--------------------------|-------------------------------|
| Chrome       | `vnc://localhost:5900`   | none (`VNC_NO_PASSWORD=1`)   |
| Firefox      | `vnc://localhost:5901`   | none                         |

Those ports and the passwordless setting come from `docker/docker-compose.dev.yml` and
`.env.selenium`.

#### Examples

**macOS**

1. Open **Finder** then **Go** then **Connect to Server**.
2. Enter the address `vnc://localhost:5900` (or `vnc://localhost:5901` for Firefox).
3. Click **Connect** and you will see the browser window executing the test inside the container.

**Linux**

```bash
sudo apt install remmina
remmina
```

This opens the **Remmina Remote Desktop Client**. In the connection window:

1. Click **+** to create a new connection.
2. Set **Protocol** to `VNC - Virtual Network Computing`.
3. Enter the server address:
   - `localhost:5900` for Chrome
   - `localhost:5901` for Firefox
4. Leave the password field empty, since `VNC_NO_PASSWORD=1`.
5. Click **Connect**.

You will then see a remote desktop window displaying the virtual browser inside the Docker
container as Selenium runs the test.

**Windows**

1. Download and install [RealVNC Viewer](https://www.realvnc.com/en/connect/download/viewer/).
2. Open RealVNC Viewer and enter one of the following addresses:
   - `localhost:5900` for Chrome
   - `localhost:5901` for Firefox
3. Click **Connect**.
4. The remote desktop window opens, showing the live browser session running inside the Docker
   container as Selenium performs each step of the test.

## Vagrant environment

{: .important }
> <i class="fa-solid fa-triangle-exclamation"></i> **Note on the Vagrant environment**
>
> `rosemary selenium` is **not yet available in Vagrant environments**. With `WORKING_DIR=/vagrant/`
> the command reports that Selenium tests cannot be run and exits. GUI testing is currently
> supported in local and Docker environments only.

## Selenium IDE

**Selenium IDE** is a browser extension for Chrome and Firefox that lets you record, edit and debug
web application tests without writing code. It is a quick way to draft an interface test that you
then clean up by hand.

### Installation

- **Chrome**: install the extension from the [Chrome Web Store](https://chrome.google.com/webstore/detail/selenium-ide/mooikfkahbdckldjjndioackbalphokd).
- **Firefox**: install the extension from [Firefox Add-ons](https://addons.mozilla.org/en-US/firefox/addon/selenium-ide/).

Once installed, the Selenium IDE icon appears in your browser toolbar.

### Recording a test

1. Open Selenium IDE from the toolbar.
2. Create a new project and set the base URL:
   - `http://localhost:5000` when running locally
   - `http://nginx_web_server_container` when running inside Docker
3. Start recording your interactions with the application.
4. Stop the recording when you are done.
5. Save the test case.

### Turning a recording into a test

Export the recording to Python pytest format, then move the code into the feature's e2e file:

```
app/features/<feature>/tests/test_selenium.py
```

Adapt the generated code so it uses the project's own helpers and carries the marker. The exported
skeleton uses `setup_method`/`teardown_method`; the tests in this repo build and close the driver
inside each test instead:

```python
import pytest

from selenium.webdriver.common.by import By

from tests.selenium_support import close_driver, get_host_for_selenium_testing, initialize_driver

pytestmark = pytest.mark.e2e


def test_something():
    driver = initialize_driver()
    try:
        driver.get(f"{get_host_for_selenium_testing()}/login")
        driver.find_element(By.NAME, "email").send_keys("user1@example.com")
        # ...
    finally:
        close_driver(driver)
```

Then run it the normal way:

```bash
rosemary test <feature> --e2e
```

{: .warning-title }
> <i class="fa-solid fa-triangle-exclamation"></i> Do not use `--noconftest`
>
> Older instructions ran exported recordings with
> `pytest --noconftest app/modules/auth/tests/test_selenium_ide/test_signup.py`. That path no longer
> exists, and `--noconftest` now breaks the run: the root `conftest.py` is what sets `SPLENT_APP`
> and provides the shared fixtures. Use `rosemary test <feature> --e2e` or
> `rosemary selenium <feature>`.

---

## Summary

| **Environment** | **How to run** | **Browser** | **Notes** |
|------------------|----------------|--------------|------------|
| Local            | `rosemary selenium auth --driver firefox` | Chrome or Firefox on the host | Opens a real browser window, targets `http://localhost:5000` |
| Docker (Grid)    | `rosemary selenium auth --driver chrome` | Chrome or Firefox in containers | Runs on the grid, targets the nginx container |
| Either           | `rosemary test auth --e2e` | Chrome, unless you export `SELENIUM_BROWSER` yourself | The same tests, selected by marker |
| VNC view         | `vnc://localhost:5900` or `vnc://localhost:5901` | Remote viewer | Watch a run live |
| Selenium IDE     | Export to Python, adapt, save as `test_selenium.py` | Chrome or Firefox | Record and edit visually |
