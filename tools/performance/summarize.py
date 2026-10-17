"""Summarize document_performance logs without reading the measured notes.

Usage: python tools/performance/summarize.py LOG [LOG ...]
Multiple fresh-process logs give a first-frame median. Scroll p95 uses the
nearest-rank definition, with idle and scroll samples reported separately.
"""
import math
import re
import statistics
import sys
from collections import defaultdict
from pathlib import Path

samples = defaultdict(list)
pattern = re.compile(r"event=document_frame sample=(\d+) elapsed_ns=(\d+).*phase=(\w+)")
for filename in sys.argv[1:]:
    for line in Path(filename).read_text().splitlines():
        match = pattern.search(line)
        if match:
            _, elapsed, phase = match.groups()
            samples[phase].append(int(elapsed) / 1_000_000)
if not samples:
    raise SystemExit("No document_performance frame samples found")
for phase, values in samples.items():
    ordered = sorted(values)
    p95 = ordered[math.ceil(0.95 * len(ordered)) - 1]
    print(f"phase={phase} samples={len(values)} median_ms={statistics.median(values):.3f} "
          f"p95_ms={p95:.3f} max_ms={max(values):.3f}")
