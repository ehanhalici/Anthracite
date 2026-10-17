"""Pinned-data case-map checks; never use Python's host Unicode casing."""
import importlib.util
from pathlib import Path
import struct
import unittest

ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location("search_case_map", ROOT / "tools/search/compile_case_map.py")
COMPILER = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(COMPILER)


def record(scalar, upper="", lower="", title=""):
    fields = [f"{scalar:04X}"] + [""] * 14
    fields[12:15] = [upper, lower, title]
    return ";".join(fields)


class CaseMapTests(unittest.TestCase):
    def test_bidirectional_transitive_simple_case(self):
        source = "\n".join((record(0x41, lower="0061"), record(0x61, upper="0041"),
                            record(0x10400, lower="10428"), record(0x10428, upper="10400")))
        pairs = dict(COMPILER.compile_map(source))
        self.assertEqual(pairs.get(0x41, 0x41), pairs.get(0x61, 0x61))
        self.assertEqual(pairs.get(0x10400, 0x10400), pairs.get(0x10428, 0x10428))

    def test_existing_turkish_i_policy(self):
        pairs = dict(COMPILER.compile_map(""))
        self.assertEqual([pairs.get(cp, cp) for cp in COMPILER.TURKISH_I], [ord("i")] * 4)

    def test_binary_header_and_record_length(self):
        pairs = COMPILER.compile_map(record(0x61, upper="0041"))
        blob = COMPILER.encode(pairs)
        self.assertEqual(struct.unpack_from("<III", blob), (COMPILER.MAGIC, COMPILER.VERSION, len(pairs)))
        self.assertEqual(len(blob), 12 + 8 * len(pairs))

    def test_malformed_record_rejected(self):
        with self.assertRaises(ValueError):
            COMPILER.compile_map("0041;not-a-UCD-record")

    def test_all_pinned_case_relations_and_idempotence(self):
        source = (ROOT / "vendor/unicode/18.0.0/UnicodeData.txt").read_text(encoding="utf-8")
        pairs = dict(COMPILER.compile_map(source))
        self.assertGreater(len(pairs), 1500)
        for scalar, folded in pairs.items():
            self.assertEqual(pairs.get(folded, folded), folded, hex(scalar))
        for line in source.splitlines():
            fields = line.split(";")
            scalar = int(fields[0], 16)
            for column in COMPILER.CASE_COLUMNS:
                if fields[column]:
                    target = int(fields[column], 16)
                    self.assertEqual(pairs.get(scalar, scalar), pairs.get(target, target), hex(scalar))


if __name__ == "__main__":
    unittest.main()
