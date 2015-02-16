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


def main():
    # open file with grade data.
    entries = get_grades_from_file(GRADES_FILE)
    # given data, enter grades
    enter_grades_mycourses(entries)


def get_grades_from_file(filename):
    """
    Opens file named filename where each line is:
    grade[\t]feedback

    It is meant to parse direct copy/paste from any spreadsheet.

    :param filename:
    :return: entry array (i.e. [EntryObject1, EntryObject2, ...]
    """
    entries = []
    with open(filename) as f:
        lines = f.readlines()

    for line in lines:
        split = line.split('\t')

        grade = split[0]
        if is_number(grade.strip()):
            entry = GradeEntry(grade, split[1])
            entries.append(entry)
        else:
            print("Grade not parsed correctly. Make sure to have grades and comments tab delimited")
            sys.exit()

    return entries


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


def enter_grades_mycourses(entries):
    """
    Actually opens up a selemium webdriver
    prompts the user to login and navigate to page
    for grades and inputs them.
    User must submit manually before final input prompt.
    Final input prompt closes the browser.
    Driver closes at the end
    :param entries:
    :return:
    """
    d = webdriver.Firefox()
    w = WebDriverWait(d, 10)  # Waiting mechanism

    d.get("http://www.mycourses.rit.edu")
    input("Please log in and navigate to grade entry page and press Enter")

    grade_textboxes = d.find_element_by_id("z_p").find_elements_by_class_name("d_edt")

    # check if textbox size == grade size
    if len(grade_textboxes) != len(entries):
        d.close()
        sys.exit()

    for i in range(len(grade_textboxes)):
        # ############
        # Enter Grades
        # ############
        textbox = grade_textboxes[i]
        grade = entries[i].grade
        textbox.send_keys(grade)
        time.sleep(0.3)

        # ############
        # Enter feedback
        # ############
        xpath = FeedbackXpath(i + 4).xpath
        feedback_button = w.until(EC.presence_of_element_located((By.XPATH, xpath)))
        feedback_button.click()

        try:
            # Dealing with iFrame and myCourses Modals
            # Must switch to modal frame and then comment subframe.
            # Submit button is in default_content frame.
            w.until(EC.visibility_of_element_located(
                (By.XPATH, '//*[@id="d2l_body"]/div[9]/div/div[1]/table/tbody/tr/td[1]/a[1]')))
            w.until(EC.visibility_of_element_located((By.XPATH, '//*[@id="d2l_form"]')))
            feedback_frame = d.find_elements_by_tag_name('iframe')[1]
            d.switch_to.frame(feedback_frame)

            sub_frames = d.find_elements_by_tag_name('iframe')
            student_comment_frame = sub_frames[0]
            instructor_comment_frame = sub_frames[1]

            d.switch_to.frame(student_comment_frame)
            tbox = w.until(EC.presence_of_element_located((By.ID, "tinymce")))
            tbox.send_keys(entries[i].feedback)
            d.switch_to.default_content()
            submit_btn = d.find_element_by_xpath('//*[@id="d2l_body"]/div[9]/div/div[1]/table/tbody/tr/td[1]/a[1]')
            submit_btn.click()

        except Exception as e:
            print("Error while trying to add comments, exiting...")
            print("No grades were submitted or altered.")
            print(e)
            sys.exit()

    input("Grades should be inputted, revise and submit")
    d.close()


class FeedbackXpath:
    """
    Class to build an xpath for a feedback button
    """

    def __init__(self, elm):
        self.elm = str(elm)
        self.part_one = '//*[@id="z_p"]/tbody/tr['
        self.part_two = ']/td[6]/a'
        self.xpath = self.part_one + self.elm + self.part_two


class GradeEntry:
    """
    Simple Generic Grade entry, has a grade and feedback
    """

    def __init__(self, grade, feedback):
        self.grade = str(grade).strip()
        self.feedback = str(feedback).strip()


if __name__ == "__main__":
    main()