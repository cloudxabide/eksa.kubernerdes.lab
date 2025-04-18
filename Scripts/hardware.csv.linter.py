#!/usr/bin/env python3

import csv
import re
import sys
from collections import Counter

def lint_hardware_csv(file_path):
    line_number = 0
    errors = []

    with open(file_path, mode='r') as file:
        reader = csv.reader(file)
        hostnames = []
        lines = list(reader)

        for line_number, row in enumerate(lines, start=1):
            if len(row) not in [8, 11]:
                errors.append(f"Line {line_number}: Invalid number of fields. Expected 8 or 11, got {len(row)}.")
                continue

            hostname = row[0]
            if Counter(hostnames)[hostname] > 0:
                errors.append(f"Line {line_number}: Duplicate hostname '{hostname}'.")
            else:
                hostnames.append(hostname)

    return errors

def main():
    if len(sys.argv) != 2:
        print("Usage: python linter.py <path_to_hardware.csv>")
        sys.exit(1)

    file_path = sys.argv[1]
    errors = lint_hardware_csv(file_path)

    if errors:
        print("Linting errors found:")
        for error in errors:
            print(error)
    else:
        print("No linting errors found.")

if __name__ == "__main__":
    main()
