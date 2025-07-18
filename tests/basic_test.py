from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.common.action_chains import ActionChains
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.chrome.service import Service
import time
import pytest
import os

mocking = os.getenv('MOCKING', default='false').lower()
mock_value = 200
mock_value_increments = [0, 1000]
mock_value_index = -1
if mocking == 'true':
    web_address = 'file:///' + os.path.join(
        os.path.dirname(__file__), 'mocking_test.html'
    )
else:
    web_address = "http://192.168.42.1/#/"

ir_sensor_min_high_value = 1000.
ir_sensor_max_low_value = 300.


def average_ir_value(driver, cycles_to_average=10):
    if mocking == 'true':
        global mock_value_index
        mock_value_index += 1
        return mock_value + mock_value_increments[mock_value_index]
    else:
        value = 0.
        for _ in range(cycles_to_average):
            element = driver.find_element(
                By.XPATH, "//div[contains(text(), 'voorkant:')]"
            )
            value += int(element.text.split(":")[1].strip())
            time.sleep(0.1)  # small delay to get different readings
        return value / cycles_to_average


@pytest.fixture(scope="module")
def driver():
    location = os.getenv('CHROMEWEBDRIVER')
    if not location:
        driver = webdriver.Chrome()
    else:
        # See: https://github.com/orgs/community/discussions/44279
        chrome_service = Service(location + "/chromedriver")
        chrome_options = Options()
        for option in ['--headless', '--disable-gpu',
                       '--window-size=1920,1200',
                       '--ignore-certificate-errors',
                       '--disable-extensions', '--no-sandbox',
                       '--disable-dev-shm-usage']:
            chrome_options.add_argument(option)
        driver = webdriver.Chrome(
            service=chrome_service, options=chrome_options
        )
    yield driver
    driver.quit()


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
    time.sleep(0.5)  # small delay to load components
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
    number_of_control_buttons = 5
    assert len(controls) == number_of_control_buttons
    assert controls[0].get_attribute('title') == 'Forward'
    assert controls[2].get_attribute('title') == 'Stop'
    assert controls[4].get_attribute('title') == 'Backward'


def test_servo_present(driver):
    driver.get(web_address)

    # find the servo slider
    element = driver.find_element(
        By.XPATH, "//div[contains(text(), 'servo:')]"
    )
    slider = element.find_element(By.XPATH, "..//input[@type='range']")

    assert element is not None
    assert slider is not None


def test_servo_slider_180(driver):
    driver.get(web_address)

    # find the servo slider
    element = driver.find_element(
        By.XPATH, "//div[contains(text(), 'servo:')]"
    )
    slider = element.find_element(By.XPATH, "..//input[@type='range']")

    # move the slider all the way to the right
    actions = ActionChains(driver)
    actions.click_and_hold(slider).move_by_offset(100, 0).release().perform()
    time.sleep(0.5)  # wait for the slider to update

    # find the new IR sensor value
    value = average_ir_value(driver)
    assert value < ir_sensor_max_low_value


def test_servo_slider_0(driver):
    driver.get(web_address)

    # find the servo slider
    element = driver.find_element(
        By.XPATH, "//div[contains(text(), 'servo:')]"
    )
    slider = element.find_element(By.XPATH, "..//input[@type='range']")

    # move the slider all the way to the left
    actions = ActionChains(driver)
    actions.click_and_hold(slider).move_by_offset(-100, 0).release().perform()
    time.sleep(0.5)  # wait for the slider to update

    # find the new IR sensor value
    value = average_ir_value(driver)
    assert value > ir_sensor_min_high_value
