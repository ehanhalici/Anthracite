"""Compile UnicodeData simple-case equivalence, without host-Python Unicode data.

Literal matching keeps one source scalar per folded scalar (no NFKC or ss/ß
expansion). Turkish dotted/dotless I retain the application's existing policy.
"""
import argparse
from pathlib import Path
import struct

MAGIC = 0x53434D50
VERSION = 1
CASE_COLUMNS = (12, 13, 14)
TURKISH_I = (0x49, 0x69, 0x130, 0x131)


def compile_map(source):
    parents = {}

    def root(value):
        parents.setdefault(value, value)
        while parents[value] != value:
            parents[value] = parents[parents[value]]
            value = parents[value]
        return value

    def join(first, second):
        a, b = root(first), root(second)
        parents[max(a, b)] = min(a, b)

    for line in source.splitlines():
        if not line or line.startswith("#"):
            continue
        fields = line.split(";")
        if len(fields) != 15:
            raise ValueError("UnicodeData records must contain 15 fields")
        scalar = int(fields[0], 16)
        for column in CASE_COLUMNS:
            if fields[column]:
                join(scalar, int(fields[column], 16))
    for scalar in TURKISH_I:
        join(TURKISH_I[0], scalar)
    turkish_root = root(TURKISH_I[0])
    pairs = []
    for scalar in sorted(parents):
        representative = root(scalar)
        if representative == turkish_root:
            representative = ord("i")
        if scalar != representative:
            pairs.append((scalar, representative))
    return pairs


def encode(pairs):
    header = struct.pack("<III", MAGIC, VERSION, len(pairs))
    return header + b"".join(struct.pack("<II", *pair) for pair in pairs)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("unicode_data", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    pairs = compile_map(args.unicode_data.read_text(encoding="utf-8"))
    args.output.write_bytes(encode(pairs))
    print(f"event=search_case_map entries={len(pairs)} version={VERSION}")


if __name__ == "__main__":
    main()
