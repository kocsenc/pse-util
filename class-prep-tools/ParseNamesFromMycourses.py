"""
Author: Kocsen Chung

Parses raw copy of the MyCourses classlist.
(Ctrl-C on highlighting the classlist)

TODO: Will be an HTML parser of the entire classlist mycourses page
"""


def main():
    with open('students.txt') as f:
        lines = f.readlines()

    parsed_lines = []
    for line in lines:
        parsed = line.strip().split('\t')
        del parsed[1]
        parsed_lines.append(parsed)

    with open('out.txt', 'w+') as f:
        for line in parsed_lines:
            name = line[0]
            split_name = name.split(' ')

            f.write(split_name[1])
            f.write('\t')
            f.write(split_name[0])
            f.write('\t')
            f.write(line[1])
            f.write('\n')


if __name__ == "__main__":
    main()


