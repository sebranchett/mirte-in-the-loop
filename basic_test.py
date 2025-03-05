from selenium import webdriver
from selenium.webdriver.common.by import By
# from selenium.webdriver.common.keys import Keys
import pytest

# web_address = "http://localhost:4000/#/"
web_address = "http://192.168.42.1/#/"

ir_sensor_min_start_value = 100


@pytest.fixture(scope="module")
def driver():
    driver = webdriver.Chrome()
    yield driver
    driver.quit()


# def test_search_python(driver):
#     driver.get("https://www.python.org/")
#     search_bar = driver.find_element(By.NAME, "q")
#     search_bar.send_keys("Python")
#     search_bar.send_keys(Keys.RETURN)
#     assert "Python" in driver.title


def test_frontend_server_reachable(driver):
    driver.get(web_address)
    assert "mirte-web-frontend" in driver.title


def test_sensors_column_present(driver):
    driver.get(web_address)
    column = driver.find_elements(
        By.XPATH, "//div[contains(text(), 'Sensors')]"
    )
    assert len(column) == 1


def test_ir_sensor_present(driver):
    driver.get(web_address)
    sensor = driver.find_elements(
        By.XPATH, "//h5[contains(text(), 'sensor')]"
    )
    assert sensor[0].text == 'IR sensor'
    assert len(sensor) == 1


def test_actuators_column_present(driver):
    driver.get(web_address)
    column = driver.find_elements(
        By.XPATH, "//div[contains(text(), 'Actuators')]"
    )
    assert len(column) == 1


def test_actuator_controls_present(driver):
    driver.get(web_address)
    controls = driver.find_elements(
        By.XPATH, "//button[contains(@class, 'btn-mirte-control')]"
    )
    # By.XPATH, "//button[@title='Forward']"
    assert len(controls) == 5


def test_value_ir_sensor(driver):
    driver.get(web_address)
    element = driver.find_element(
        By.XPATH, "//div[contains(text(), 'voorkant:')]"
    )
    value = int(element.text.split(":")[1].strip())
    assert value > ir_sensor_min_start_value
