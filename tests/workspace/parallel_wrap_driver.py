"""Parallel line shaping equals sequential shaping for every worker count.

Usage: parallel_wrap_driver.py PARALLEL_WRAP_CONTRACTS

Generates the synthetic fixture and runs the contract binary with
ANTHRACITE_WORKERS = 1, 2, 3, 5, 8, 12, each with and without random worker
timing jitter. Exit 77 (skip) when no X display is available.
"""
import os
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
WORKERS = [1, 2, 3, 5, 8, 12]
REPEAT = "5"


def main():
    binary = sys.argv[1]
    failures = 0
    with tempfile.TemporaryDirectory(prefix="anthracite-parallel-wrap-") as root:
        subprocess.run([sys.executable, str(ROOT / "tools/performance/gen_fixture.py"), root],
                       check=True, stdout=subprocess.DEVNULL)
        heavy = str(Path(root) / "heavy.md")
        for workers in WORKERS:
            for jitter in ("0", "1"):
                env = dict(os.environ, ANTHRACITE_WORKERS=str(workers), ANTHRACITE_THREAD_JITTER=jitter)
                result = subprocess.run([binary, heavy, REPEAT], env=env, capture_output=True, text=True, timeout=600)
                if result.returncode == 77:
                    print("SKIP: no X display")
                    return 77
                summary = [l for l in result.stdout.splitlines() if l.startswith("event=parallel_wrap_contracts")]
                print(f"workers={workers} jitter={jitter} rc={result.returncode} {summary[-1] if summary else 'no output'}")
                if result.returncode != 0:
                    failures += 1
                    print(result.stdout[-3000:], result.stderr[-2000:], sep="\n")
    print(f"parallel_wrap_driver failures={failures}")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
