from selenium.webdriver.common.by import By
from selenium.common.exceptions import NoSuchElementException, TimeoutException
import time
from selenium import webdriver
import selenium.webdriver.firefox.service
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC


firefox_bin = "/snap/firefox/current/usr/lib/firefox/firefox"
firefoxdriver_bin = "/snap/bin/geckodriver"

options = webdriver.firefox.options.Options()
options.binary_location = firefox_bin
options.add_argument('--headless')
service = webdriver.firefox.service.Service(executable_path=firefoxdriver_bin)
browser = webdriver.Firefox(service=service, options=options)


def test_valid_location():
    try:
        browser.get("http://localhost:5000")
        search_box = WebDriverWait(browser, 10).until(
            EC.presence_of_element_located((By.ID, 'location'))
        )
        search_box.send_keys("New York")

        submit_button = WebDriverWait(browser, 10).until(
            EC.element_to_be_clickable((By.CSS_SELECTOR, 'button[type="submit"]'))
        )
        submit_button.click()

        result = WebDriverWait(browser, 10).until(
            EC.presence_of_element_located((By.XPATH,"/html/body/div/h1"))
        )
        print(f"Result found: {result.text}")
        text = result.text
        assert("New york" in text)
    except (NoSuchElementException, TimeoutException) as e:
        print(f"Test failed: {e}")
    finally:
        #browser.quit()
        pass


def test_invalid_location():
    try:
        #options = webdriver.firefox.options.Options()
        #options.binary_location = firefox_bin
        #service = webdriver.firefox.service.Service(executable_path=firefoxdriver_bin)
        #browser = webdriver.Firefox(service=service, options=options)

        browser.get("http://localhost:5000")


        search_box = WebDriverWait(browser, 20).until(
            EC.presence_of_element_located((By.ID, 'location'))
        )
        search_box.send_keys("InvalidLocation")


        submit_button = WebDriverWait(browser, 10).until(
            EC.element_to_be_clickable((By.CSS_SELECTOR, 'button[type="submit"]'))
        )
        submit_button.click()

       
        error_message = WebDriverWait(browser, 10).until(
            EC.presence_of_element_located((By.CLASS_NAME, "alert-danger"))
        )
        print(f"Error message found: {error_message.text}")
        assert "location not found" in error_message.text

    except (NoSuchElementException, TimeoutException) as e:
        print(f"Test failed: {e}")

    finally:
        browser.quit()

