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

Selenium is a suite of web browser automation tools.  
It provides an easy-to-use interface for interacting with browsers such as Chrome and Firefox, enabling automated testing, data scraping, and other repetitive tasks in web applications.

{: .warning-title }
> <i class="fa-solid fa-triangle-exclamation"></i> VERY IMPORTANT!
>
> The application must be started before running Selenium tests.

---

## Interface testing with Rosemary

Rosemary provides a unified command for running Selenium tests both **locally** and **inside Docker** (using Selenium Grid).

To execute **all** interface tests:

```bash
rosemary selenium
```

To run a specific module’s test:

```bash
rosemary selenium <module_name>
```

You can choose the browser driver (default is firefox):

```bash
rosemary selenium <module_name> --driver firefox
```

## Local environment

If you run Rosemary outside Docker, Selenium will use your local browser drivers (geckodriver or chromedriver).

{: .note-title }
> <i class="fa-solid fa-circle-info"></i> **Note for Ubuntu users**
>
> If you are using **Ubuntu 22.04 or newer**, you **don’t need to install anything** — both **Firefox** and **GeckoDriver** come preinstalled and ready for Selenium.


Make sure they are installed:

```bash
sudo apt install firefox geckodriver
# or
sudo apt install google-chrome-stable chromedriver
```

Then simply run:

```bash
rosemary selenium auth --driver firefox
```


Your local browser window will open and execute the test automatically.

## Docker environment (Selenium Grid)

When executed inside Docker (`WORKING_DIR=/app/`), Rosemary connects automatically to a Selenium Grid defined in `docker-compose.yml`, using these services:

- selenium-hub
- selenium-chrome
- selenium-firefox

Launching the grid:

```bash
docker compose up -d selenium-hub selenium-chrome selenium-firefox
```

Check that it’s running:

```bash
curl http://localhost:4444/status | jq .
```


You should see:

```
{
  "value": { "ready": true, "message": "Selenium Grid ready." }
}
```


Then run the test inside `web_app_container`:

```bash
rosemary selenium auth --driver chrome
```

The test will execute inside the Chrome or Firefox container automatically.

### Viewing the browser in Docker (VNC)

**VNC** (Virtual Network Computing) is a remote-desktop protocol that lets you **see and control** a graphical session running on another machine (or container) over the network. 

In our setup, each Selenium browser node (Chrome/Firefox) runs its own virtual display **inside Docker** and exposes it via VNC, so you can **watch the test in real time** even though the browser window isn’t on your host desktop.

### Connect via VNC

You can connect to the running browsers using any **VNC viewer**.  
Each Selenium node exposes its own VNC port so you can watch the test sessions live.

| **Browser** | **VNC URL**              | **Default password**         |
|--------------|--------------------------|-------------------------------|
| Chrome       | `vnc://localhost:5900`   | none (`VNC_NO_PASSWORD=1`)   |
| Firefox      | `vnc://localhost:5901`   | none                         |

#### Examples

**macOS**

1. Open **Finder** → **Go** → **Connect to Server**.  
2. Enter the address `vnc://localhost:5900` (or `vnc://localhost:5901` for Firefox).  
3. Click **Connect** and you’ll see the browser window executing the test inside the container.

**Linux**

```bash
sudo apt install remmina
remmina
```

This will open the **Remmina Remote Desktop Client** interface.  
In the connection window:

1. Click **+** to create a new connection.  
2. Set **Protocol** → `VNC - Virtual Network Computing`.  
3. Enter the server address:  
   - `localhost:5900` → Chrome  
   - `localhost:5901` → Firefox  
4. Leave the password field empty (since `VNC_NO_PASSWORD=1`).  
5. Click **Connect**.  

You’ll then see a remote desktop window displaying the virtual browser inside the Docker container as Selenium runs the test.

**Windows**

1. Download and install [RealVNC Viewer](https://www.realvnc.com/en/connect/download/viewer/).  
2. Open RealVNC Viewer and enter one of the following addresses:
   - `localhost:5900` → Chrome  
   - `localhost:5901` → Firefox  
3. Click **Connect**.  
4. The remote desktop window will open, showing the live browser session running inside the Docker container as Selenium performs each step of the test.

## Vagrant environment

{: .important }
> <i class="fa-solid fa-triangle-exclamation"></i> **Note on Vagrant environment**
>
> The `rosemary selenium` command is **not yet available in Vagrant environments**.  
> GUI testing with Selenium is currently supported **only in local** and **Docker** environments.
>
> Future versions of Rosemary will include native Vagrant integration for Selenium testing.


## Selenium IDE

**Selenium IDE** (Integrated Development Environment) is a browser extension for Chrome and Firefox that allows you to **record, edit, and debug** web application tests without writing code.

It’s ideal for quickly generating interface tests that can later be exported to Python and integrated into your project.

### Installation

- **Chrome**: Install the extension from the [Chrome Web Store](https://chrome.google.com/webstore/detail/selenium-ide/mooikfkahbdckldjjndioackbalphokd).  
- **Firefox**: Install the extension from the [Firefox Add-ons](https://addons.mozilla.org/en-US/firefox/addon/selenium-ide/).

Once installed, you’ll see the Selenium IDE icon in your browser’s toolbar.

### Recording a test

1. **Open Selenium IDE** from your browser toolbar.  
2. **Create a new project** and specify the base URL — for example:  
   - `http://localhost` if running locally  
   - `http://web:5000` if running inside Docker  
3. **Start recording** your interactions with the application (clicks, inputs, navigations, etc.).  
4. **Stop** the recording once you’ve finished.  
5. **Save** your test case to reuse or export later.

### Exporting to Python

You can export your recorded tests to **Python pytest** format and include them in your project under:

```python
app/modules/<module_name>/tests/test_selenium/
```

Then, adjust the generated code to match your project’s driver initialization:

```python
def setup_method(self, method):
    self.driver = initialize_driver()
    self.vars = {}

self.driver.get(get_host_for_selenium_testing())
```
Finally, run the test with:

```
pytest --noconftest app/modules/auth/tests/test_selenium_ide/test_signup.py
```

---

## Summary

| **Environment** | **How to run** | **Browser** | **Notes** |
|------------------|----------------|--------------|------------|
| Local            | `rosemary selenium auth --driver chrome` | Chrome / Firefox (on host) | Opens the real browser window |
| Docker (Grid)    | `rosemary selenium auth --driver firefox` | Chrome / Firefox (in containers) | Runs inside Selenium Grid |
| VNC view         | `vnc://localhost:5900` / `vnc://localhost:5901` | Remote viewer | Watch tests live |
| Selenium IDE     | Export to Python pytest | Chrome / Firefox | Record, edit and run tests visually |

---

With Selenium Grid integrated into Docker, you can now run, visualize, and debug GUI tests entirely within containers — or locally when needed — using the same `rosemary selenium` command.
