from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
import pytest


@pytest.fixture(scope="module")
def driver():
    driver = webdriver.Chrome()
    yield driver
    driver.quit()


def test_search_python(driver):
    driver.get("https://www.python.org/")
    search_bar = driver.find_element(By.NAME, "q")
    search_bar.send_keys("Python")
    search_bar.send_keys(Keys.RETURN)
    assert "Python" in driver.title


def test_frontend_server_reachable(driver):
    driver.get("http://localhost:4000/#/")
    assert "mirte-web-frontend" in driver.title
