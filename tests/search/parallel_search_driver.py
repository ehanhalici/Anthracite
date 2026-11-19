"""Parallel search equals sequential search, for every worker count.

Usage: parallel_search_driver.py PARALLEL_SEARCH_CONTRACTS

Generates vaults of 50, 500 and 5000 notes (tools/performance/gen_fixture.py)
and runs the contract binary with ANTHRACITE_WORKERS = 1, 2, 3, 5, 8, 12.
Queries cover a common word (hits the 200-row limit), a rarer word, Turkish
case folding, a phrase and a query with no match.
"""
import os
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
QUERIES = ["not", "bağlantı", "BAŞLIK", "kısa satır", "zzqqxx-yok"]
WORKERS = [1, 2, 3, 5, 8, 12]
VAULTS = [50, 500, 5000]
REPEAT = "3"


def main():
    binary = sys.argv[1]
    failures = 0
    with tempfile.TemporaryDirectory(prefix="anthracite-parallel-search-") as root:
        for notes in VAULTS:
            out = Path(root) / f"v{notes}"
            subprocess.run([sys.executable, str(ROOT / "tools/performance/gen_fixture.py"), str(out),
                            "--notes", str(notes), "--sections", "4"], check=True, stdout=subprocess.DEVNULL)
            for workers in WORKERS:
                env = dict(os.environ, ANTHRACITE_WORKERS=str(workers))
                result = subprocess.run([binary, str(out / "vault"), REPEAT, *QUERIES], env=env,
                                        capture_output=True, text=True, timeout=600)
                lines = [l for l in result.stdout.splitlines() if l.startswith("event=parallel_search")]
                summary = lines[-1] if lines else "no output"
                print(f"notes={notes} workers={workers} rc={result.returncode} {summary}")
                if result.returncode != 0:
                    failures += 1
                    print("\n".join(lines), result.stderr[-2000:], sep="\n")
    print(f"parallel_search_driver failures={failures}")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
