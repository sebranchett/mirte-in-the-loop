# Integration Test with MIRTE in-the-loop

Initial example from https://www.browserstack.com/guide/python-selenium-to-run-web-automation-test.

[Selenium](https://www.selenium.dev/) and [pytest](https://docs.pytest.org/) are used to run integration tests on the [MIRTE robot](https://mirte.org/) client website.

## Installation
To get started, create and activate a conda environment:
```sh
conda env create -f environment.yml
conda activate mirte-itl
```

## Usage
To run the tests, make sure that MIRTE is on and set up for physical testing.

<img src="./assets/testingPOC.jpg" alt="Testing POC" width="300"/>

Connect to MIRTE's WiFi and type the following:
```sh
pytest
```
There should be no errors and all tests should pass.
