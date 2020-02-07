#!/usr/bin/env python

# source: https://github.com/zygmuntz/phraug/blob/master/csv2libsvm.py

# usage: python3 csv2libsvm.py testdata.csv testdata.libsvm 0 True

"""
Convert CSV file to libsvm format. Works only with numeric variables.
Put -1 as label index (argv[3]) if there are no labels in your file.
Expecting no headers. If present, headers can be skipped with argv[4] == 1.

"""

import sys
import csv
from collections import defaultdict


def construct_line(label, line):
    new_line = []
    if float(label) == 0.0:
        label = "0"
    new_line.append(label)

    for i, item in enumerate(line):
        if item == '' or float(item) == 0.0:
            continue
        new_item = "%s:%s" % (i + 1, item)
        new_line.append(new_item)
    new_line = " ".join(new_line)
    new_line += "\n"
    return new_line

# ---


label_index = int(0)

i = sys.stdin
o = sys.stdout

reader = csv.reader(i)

headers = next(reader)

for line in reader:
    if label_index == -1:
        label = '1'
    else:
        label = line.pop(label_index)

    new_line = construct_line(label, line)
    o.write(new_line)
