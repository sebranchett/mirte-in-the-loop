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
To run the tests, execute the following command:
```sh
pytest
```
There should be no errors and all tests should pass.
