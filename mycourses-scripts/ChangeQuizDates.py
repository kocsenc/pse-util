__author__ = 'kocsen'

import time
import datetime

from selenium import webdriver
from selenium.common.exceptions import *
from selenium.webdriver.common.keys import Keys


week = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']


def main():
    """
    Entry-point
    :return:
    """
    driver = webdriver.Firefox()
    driver.get("http://www.mycourses.rit.edu")
    login(driver)
    go_to_quiz_section(driver)

    week_interval = datetime.timedelta(2)
    weekend_interval = datetime.timedelta(3)

    start_date = datetime.date(2015, 1, 26)
    quiz_date = datetime.date(2015, 1, 26)

    count = 1
    for quiz_num in range(len(get_quiz_elements(driver))):
        if quiz_num + 1 <= 24:
            if quiz_date.weekday() >= 4:
                quiz_date += weekend_interval
            else:
                quiz_date += week_interval

            if quiz_num + 1 == 24:
                quiz_date += datetime.timedelta(7)
            continue

        quiz_rows = get_quiz_elements(driver)
        element = quiz_rows[quiz_num]

        print('Editting ' + element.get_attribute('title')[12:])
        print('To date: ' + week[quiz_date.weekday()] + ' ' + quiz_date.isoformat())

        element.click()

        for option in element.parent.find_elements_by_tag_name('span'):
            if option.text == 'Edit Quiz':
                option.click()
                break

        # Go to time/restrictions
        tabs = driver.find_elements_by_class_name('d_tabs_header')
        tabs_table = tabs[0].find_elements_by_tag_name('table')
        actual_tabs = tabs_table[0].find_elements_by_tag_name('td')
        actual_tabs[1].click()
        modify_quiz(driver, quiz_date.strftime("%-m/%-d/%Y"))

        if quiz_date.weekday() >= 4:
            quiz_date += weekend_interval
        else:
            quiz_date += week_interval

            # if count % 3 == 0:
            # input('Enter to Modify next quiz batch')
        count += 1

    input('all done, press enter to finish')
    driver.close()


def modify_quiz(driver, date, time=""):
    """
    Once in the restriction tab of a quiz, will set the date and time given.

    Needs sleeps to simulate human

    :param driver:
    :param date:
    :param time:
    :return:
    """
    time.sleep(2)
    # Change Dates
    start_date_field = driver.find_element_by_id('dateR_dts_sd')
    end_date_field = driver.find_element_by_id('dateR_dts_ed')

    start_date_field.click()
    for i in range(10):
        start_date_field.send_keys(Keys.DELETE)
        time.sleep(0.3)
    for char in date:
        start_date_field.send_keys(char)
        time.sleep(0.1)
    driver.find_element_by_xpath('//*[@id="ctl_9"]/div[3]/table[1]/tbody/tr[1]/td/h2').click()
    time.sleep(1)

    end_date_field.click()
    for i in range(10):
        end_date_field.send_keys(Keys.DELETE)
        time.sleep(0.3)
    for char in date:
        end_date_field.send_keys(char)
        time.sleep(0.1)
    driver.find_element_by_xpath('//*[@id="ctl_9"]/div[3]/table[1]/tbody/tr[1]/td/h2').click()
    time.sleep(1)

    driver.find_element_by_xpath('//*[@id="z_a"]').click()


def go_to_quiz_section(driver, class_name='SWEN.250.02 - Personal Software Engineering [Martinez] 11am'):
    """
    Goes to martinez class (default), then click on quizzes.
    :param driver:
    :return:
    """
    try:
        go_to_class(driver, class_name).click()
        time.sleep(1)
        driver.find_element_by_xpath(
            '//*[@id="d2l_navbar"]/div/div[1]/div/div[1]/div[3]/div/div[1]/div[2]/div/div/div[1]/ul/li[8]').find_element_by_tag_name(
            'a').click()
    except NoSuchElementException:
        input("No element found, navigate to course and section and press enter to continue")


def get_quiz_elements(driver):
    table = driver.find_element_by_id("z_d")
    all_quiz_rows = table.find_elements_by_tag_name('a')
    return [x for x in all_quiz_rows if "Actions for" in x.get_attribute('title')]


def go_to_class(driver, class_name):
    """
    Navigates to a class described by class_name
    PRECONDITION: needs to be logged in

    :param driver: Selenium driver
    :param class_name:
    :return:
    """
    for elm in driver.find_elements_by_tag_name('a'):
        if elm.text == class_name:
            return elm


def login(d):
    """
    Prompts
    Logs in
    :param d: driver
    :return:
    """
    username = d.find_element_by_xpath('//*[@id="login_box"]/form/div[1]/div[2]/input')
    username_input = input('MyCourses User: ')
    username.send_keys(username_input)

    pass_field = d.find_element_by_xpath('//*[@id="login_box"]/form/div[2]/div[2]/input')
    password = input('MyCourses Password: ')
    pass_field.send_keys(password)

    pass_field.submit()


if __name__ == "__main__":
    main()
