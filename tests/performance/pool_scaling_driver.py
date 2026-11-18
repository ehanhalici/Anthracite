"""Worker pool scaling and contention check (CTest label perf).

Usage: pool_scaling_driver.py PARALLEL_WRAP_CONTRACTS

Runs parallel line shaping of the synthetic fixture with 1, 2, 4 and all
workers, with per-worker hardware counters (ANTHRACITE_WORKER_COUNTERS=1):

- total instructions within 10% of the single-worker run (work does not grow),
- total cycles at most 1.25x (cores do not stall each other: no shared hot
  cache lines, no lock convoys),
- cache misses below 0.5 per 1000 instructions for every worker count (each
  worker warms its own font copy; false sharing would multiply this),
- wall-time speedup at least 1.6x with 2 workers and 2.5x with 4.

Exit 77 (skip) without a display, without hardware counters, or when the
machine is busy (load average above a quarter of the CPUs).
"""
import os
import re
import statistics
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SKIP = 77
REPEAT = "6"


def busy():
    return os.getloadavg()[0] > os.cpu_count() / 4


def run(binary, heavy, workers):
    env = dict(os.environ, ANTHRACITE_WORKERS=str(workers), ANTHRACITE_WORKER_COUNTERS="1")
    result = subprocess.run([binary, heavy, REPEAT], env=env, capture_output=True, text=True, timeout=600)
    if result.returncode == SKIP:
        return None
    if result.returncode != 0:
        raise SystemExit(f"workers={workers} failed rc={result.returncode}\n{result.stdout[-2000:]}")
    runs = [int(m.group(2)) for m in re.finditer(r"run=(\d+) errors=0 elapsed_ns=(\d+)", result.stdout)
            if m.group(1) != "0"]  # run 0 also opens every worker's font
    pool = dict(re.findall(r"(\w+)=(\d+)", next(l for l in result.stdout.splitlines() if l.startswith("event=parallel_wrap_pool"))))
    return {"wall": statistics.median(runs), **{k: int(v) for k, v in pool.items()}}


def main():
    binary = sys.argv[1]
    if busy():
        print("SKIP: machine busy")
        return SKIP
    with tempfile.TemporaryDirectory(prefix="anthracite-pool-scaling-") as root:
        subprocess.run([sys.executable, str(ROOT / "tools/performance/gen_fixture.py"), root], check=True, stdout=subprocess.DEVNULL)
        heavy = str(Path(root) / "heavy.md")
        counts = [1, 2, 4]
        all_workers = max(1, len(os.sched_getaffinity(0)) // 2 - 1)
        if all_workers > 4:
            counts.append(all_workers)
        results = {}
        for n in counts:
            r = run(binary, heavy, n)
            if r is None:
                print("SKIP: no X display")
                return SKIP
            results[n] = r
    base = results[1]
    if base["cycles"] == 0:
        print("SKIP: hardware counters unavailable")
        return SKIP
    failures = []
    for n, r in results.items():
        speedup = base["wall"] / r["wall"]
        inst = r["instructions"] / base["instructions"]
        cyc = r["cycles"] / base["cycles"]
        mpki = 1000.0 * r["cache_misses"] / max(1, r["instructions"])
        print(f"event=pool_scaling workers={n} wall_ms={r['wall'] / 1e6:.1f} speedup={speedup:.2f} "
              f"instructions_ratio={inst:.3f} cycles_ratio={cyc:.3f} misses_per_kinst={mpki:.3f} steals={r['steals']}")
        if not 0.9 <= inst <= 1.1:
            failures.append(f"workers={n}: instructions ratio {inst:.3f}")
        if cyc > 1.25:
            failures.append(f"workers={n}: cycles ratio {cyc:.3f} (contention)")
        if mpki > 0.5:
            failures.append(f"workers={n}: {mpki:.3f} cache misses per 1000 instructions")
        if n == 2 and speedup < 1.6:
            failures.append(f"workers=2: speedup {speedup:.2f}")
        if n == 4 and speedup < 2.5:
            failures.append(f"workers=4: speedup {speedup:.2f}")
    for f in failures:
        print("FAIL", f)
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
