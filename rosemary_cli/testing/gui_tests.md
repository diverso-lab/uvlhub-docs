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

## Introduction to Selenium

Selenium is a suite of web browser automation tools. It provides an easy-to-use interface for interacting with browsers such as Chrome, Firefox and Safari, enabling automated testing, data scraping and other repetitive tasks in web applications.

## Interface testing in local environment

To perform all interface tests in local environment, use:

```
rosemary selenium
```

You can run an interface test of a specific module:

```
rosemary selenium <module_name>
```

## Interface testing in Docker and Vagrant environment

{: .note-title }
> <i class="fa-solid fa-terminal"></i> Rosemary CLI not available
>
> Currently it is not possible to use Rosemary CLI to run Selenium in Docker and/or Vagrant environment. This is a feature that will be added in the future.

{: .important }
>
> You have to do this in the local environment.

### Activate the virtual environment

It is recommended to use the virtual environment. 

```
python3.12 -m venv venv
source venv/bin/activate
```

### Install dependencies

```
pip install -r requirements.txt
pip install -e ./
```

### Run test

To run the interface test of a module in this environment, run:

```
python app/modules/<module_name>/tests/test_selenium.py 
```

Remember to replace `<module_name>` with the name of the module you want to test.

---

## Selenium IDE

Selenium IDE (Integrated Development Environment) is a tool for recording, editing, and debugging web application tests. It is a browser extension available for both Chrome and Firefox that allows users to create test cases quickly without any programming knowledge. Selenium IDE is particularly useful for creating simple and quick tests, making it an excellent choice for beginners.

### Installation

1. **Chrome**: Install the Selenium IDE extension from the [Chrome Web Store](https://chrome.google.com/webstore/detail/selenium-ide/mooikfkahbdckldjjndioackbalphokd).
2. **Firefox**: Install the Selenium IDE extension from the [Firefox Add-ons](https://addons.mozilla.org/en-US/firefox/addon/selenium-ide/).

### Recording a test

1. **Open Selenium IDE**: After installation, click on the Selenium IDE icon in the browser toolbar to open it.

2. **Create a new project**:
   - Click on `Create a new project`.
   - Name your project and click `OK`.

3. **Start recording**:
   - Click on the `Record a new test in a new project` button.
   - Enter the base URL of your application, e.g., `http://localhost`, and click `Start Recording`.

4. **Navigate to the desired page**:
   - In the browser, go to the page you want to test.
   - Selenium IDE will record your navigation to this page.

5. **Perform actions**:
   - Perform the actions you want to test. Selenium IDE will record each of these actions.

6. **Stop recording**:
   - Once you have performed all the necessary actions, click on the `Stop recording` button in Selenium IDE.

7. **Save the test**:
   - Name your test case and save it.

### Playback the recorded test

1. **Select the test case**: In Selenium IDE, select the test case you want to playback.

2. **Run the Test**: Click on the `Run current test` button. Selenium IDE will execute the recorded actions.

### Exporting the test script

If you want to export the test script for use with Selenium WebDriver, follow these steps:

- Click on the `Export` button.
- Choose `Python pytest` and location to save the file in `app/modules/<module_name>/tests/test_selenium/`

### Using the test in the project

{: .important }
>
> You have to do this in the local environment.

1. **Adjust the generated test**

Remember to adjust the generated test to the project.

```
  def setup_method(self, method):
    self.driver = initialize_driver()
    self.vars = {}
```

```
self.driver.get(get_host_for_selenium_testing())
```

2. **Run the test with pytest**.

```
pytest --noconftest app/modules/auth/tests/test_selenium_ide/test_signup.py
```

Selenium IDE makes it easy to create, edit, and run automated tests for web applications, providing a great starting point for anyone new to test automation.


## Using WSL2 (Windows Subsystem for Linux) and WebDriver

### Install Google Chrome version 114

```
cd $HOME
wget --no-verbose -O /tmp/chrome.deb https://dl.google.com/linux/chrome/deb/pool/main/g/google-chrome-stable/google-chrome-stable_114.0.5735.198-1_amd64.deb && sudo apt install -y /tmp/chrome.deb && rm /tmp/chrome.deb
```

### Install ChromeDriver

```
chrome_driver="114.0.5735.90"
curl -Lo chromedriver_linux64.zip "https://chromedriver.storage.googleapis.com/${chrome_driver}/chromedriver_linux64.zip"
```

### Unzip and make ChromeDriver executable

```
mkdir -p "chromedriver/stable" && \
unzip -q "chromedriver_linux64.zip" -d "chromedriver/stable" && \
chmod +x "chromedriver/stable/chromedriver"
```

### Move the ChromeDriver executable to the WSL2 path

```
sudo cp ~/chromedriver/stable/chromedriver /usr/bin/
```