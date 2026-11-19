"""Summarize document_performance / search_performance logs.

Usage:
  python tools/performance/summarize.py [--json] [--compare BASE.json] LOG [LOG ...]

Multiple fresh-process logs give a first-frame median. p95 uses the nearest-rank
definition. Every frame label (first, warm_idle, warm_scroll_<scenario>, ...) is
reported separately for: wall time, cpu_ns (draw + rend_flush, excluding glFinish
and swap, so VSync does not hide CPU cost), each perf_phase total and each counter.
--compare prints the percentage change of every median against a previous --json.
"""
import argparse
import json
import math
import re
import statistics
import sys
from collections import defaultdict
from pathlib import Path

FRAME = re.compile(r"event=document_frame sample=(\d+) elapsed_ns=(\d+)(.*?)phase=(\w+)")
FIELD = re.compile(r"(\w+)_ns=(\d+)")
COUNTER = re.compile(r"event=performance_counter name=(\w+) value=(\d+)")
PHASE = re.compile(r"event=perf_phase name=(\w+) calls=(\d+) total_ns=(\d+)")
SEARCH = re.compile(r"event=literal_search_benchmark (.*)")
KV = re.compile(r"(\w+)=(-?\d+)")


def p95(values):
    ordered = sorted(values)
    return ordered[math.ceil(0.95 * len(ordered)) - 1]


def stats(values):
    return {"samples": len(values), "median": statistics.median(values),
            "p95": p95(values), "max": max(values)}


def parse(paths):
    """Return {label: {metric: [values]}}; frame metrics use ms, counters raw."""
    data = defaultdict(lambda: defaultdict(list))
    for filename in paths:
        current = None
        for line in Path(filename).read_text().splitlines():
            frame = FRAME.search(line)
            if frame:
                _, elapsed, extra, current = frame.groups()
                data[current]["elapsed_ms"].append(int(elapsed) / 1e6)
                for name, value in FIELD.findall(extra):
                    data[current][f"{name}_ms"].append(int(value) / 1e6)
                continue
            if current is not None:
                counter = COUNTER.search(line)
                if counter:
                    data[current][f"counter.{counter.group(1)}"].append(int(counter.group(2)))
                    continue
                phase = PHASE.search(line)
                if phase:
                    name, calls, total = phase.groups()
                    if int(calls) > 0:
                        data[current][f"phase.{name}_ms"].append(int(total) / 1e6)
                    continue
            search = SEARCH.search(line)
            if search:
                fields = dict(KV.findall(search.group(1)))
                if "elapsed_ns" in fields:
                    data["search"]["elapsed_ms"].append(int(fields.pop("elapsed_ns")) / 1e6)
                fields.pop("run", None)
                for key, value in fields.items():
                    data["search"][f"counter.{key}"].append(int(value))
    return data


def summarize(data):
    return {label: {metric: stats(values) for metric, values in metrics.items()}
            for label, metrics in data.items()}


def print_text(summary, base=None):
    for label, metrics in summary.items():
        wall = metrics.get("elapsed_ms")
        if wall:
            print(f"phase={label} samples={wall['samples']} median_ms={wall['median']:.3f} "
                  f"p95_ms={wall['p95']:.3f} max_ms={wall['max']:.3f}")
        for metric in sorted(metrics):
            if metric == "elapsed_ms":
                continue
            s = metrics[metric]
            line = f"  {metric:<32} median={s['median']:>12.3f} p95={s['p95']:>12.3f} max={s['max']:>12.3f}"
            old = (base or {}).get(label, {}).get(metric)
            if old and old["median"]:
                line += f"  ({100.0 * (s['median'] - old['median']) / old['median']:+.1f}% vs base)"
            print(line)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("logs", nargs="+")
    ap.add_argument("--json", action="store_true", help="emit machine-readable summary")
    ap.add_argument("--compare", type=Path, help="previous --json summary to diff against")
    args = ap.parse_args()
    data = parse(args.logs)
    if not data:
        raise SystemExit("No document_performance frame samples found")
    summary = summarize(data)
    if args.json:
        json.dump(summary, sys.stdout, indent=1, sort_keys=True)
        print()
        return
    base = json.loads(args.compare.read_text()) if args.compare else None
    print_text(summary, base)


if __name__ == "__main__":
    main()
