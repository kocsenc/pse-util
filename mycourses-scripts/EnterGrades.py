import time

__author__ = 'kocsen'

"""
Given a list of grades in order, will insert them into
mycourses Grade Entry page.
"""
from selenium import webdriver
import sys

from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC


GRADES_FILE = "grades.txt"


def main():  # TODO: Add feature to also add feedback/comments
    # open file with grade data.
    grades = get_grades_from_file(GRADES_FILE)
    # given data, enter grades
    enter_grades_mycourses(grades)


def get_grades_from_file(filename):
    """
    Opens file named filename where each line
    is a grade.

    :param filename:
    :return: string array (i.e. ["4","6"...]
    """
    # Parses file and returns grades in array in string format
    grades = []
    with open(filename) as f:
        lines = f.readlines()

    for line in lines:
        line = line.strip()
        if is_number(line):
            grades.append(line)

    return grades


def is_number(s):
    """
    Simple helper to check if number
    :param s:
    :return:
    """
    try:
        float(s)
        return True
    except ValueError:
        pass

    try:
        import unicodedata

        unicodedata.numeric(s)
        return True
    except (TypeError, ValueError):
        pass

    return False


def enter_grades_mycourses(grades):
    """
    Actually opens up a selemium webdriver
    prompts the user to login and navigate to page
    for grades and inputs them.
    User must submit manually before final input which closes
    the browser.
    Driver closes at the end
    :param grades:
    :return:
    """
    d = webdriver.Firefox()
    w = WebDriverWait(d, 10) # Waiting mechanism

    d.get("http://www.mycourses.rit.edu")
    input("Please log in and navigate to grade entry page and press Enter")

    grade_textboxes = d.find_element_by_id("z_p").find_elements_by_class_name("d_edt")

    # check if textbox size == grade size
    if len(grade_textboxes) != len(grades):
        d.close()
        sys.exit()

    # Enter Grades
    for i in range(len(grade_textboxes)):
        textbox = grade_textboxes[i]
        grade = grades[i]
        textbox.send_keys(grade)
        time.sleep(0.3)

    # Enter feedback
    for i in range(len(grade_textboxes)):
        xpath = FeedbackXpath(i + 5).xpath
        feedback_button = d.find_element_by_xpath(xpath)
        feedback_button.click()
        try:
            # MyCourses still wont recognize this id
            feedback_area = w.until(EC.presence_of_element_located((By.ID, "tinymce")))
        finally:
            print("oh oh")
            sys.exit()

    input("Grades should be inputted, revise and submit")
    d.close()


class FeedbackXpath:
    def __init__(self, elm):
        self.elm = str(elm)
        self.part_one = '//*[@id="z_p"]/tbody/tr['
        self.part_two = ']/td[6]/a'
        self.xpath = self.part_one + self.elm + self.part_two


if __name__ == "__main__":
    main()