"""
Author: Kocsen Chung

Parses raw copy of the MyCourses classlist.

To use:
    Navigate to Classlist > (top-right) Print > Select Students Tab > Higlight table body and copy to clipboard
    Save the contents of the clipboard to a file `students.txt` and run this script, expect an out.txt

TODO: Will be an HTML parser of the entire classlist mycourses page
"""


def main():
    with open('students.txt') as f:
        lines = f.readlines()

    parsed_lines = []
    for line in lines:
        parsed = line.strip().split('\t')
        parsed_lines.append(parsed)

    with open('out.txt', 'w+') as f:
        for line in parsed_lines:
            uid = line[1]
            first, last = parse_name(line[0])

            f.write(last)
            f.write('\t')
            f.write(first)
            f.write('\t')
            f.write(uid)
            f.write('\n')

def parse_name(raw_name):
    ary = raw_name.split(',')
    if 'is online' in raw_name:
        last = ary[0]

        dup_fname = ary[1].strip().split(' ')[0]
        cut_at = int(len(dup_fname)/2)

        first = dup_fname[:cut_at]

        return (first,last)
    else:
        return (ary[0].strip(), ary[1].strip())



if __name__ == "__main__":
    main()


