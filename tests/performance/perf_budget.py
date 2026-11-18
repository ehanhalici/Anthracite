"""Deterministic performance budgets (counters, not wall time).

Usage: perf_budget.py DOCUMENT_PERFORMANCE SEARCH_PERFORMANCE

Generates the synthetic fixture, runs the read-mode wheel scenario and the
literal search benchmark, then checks work counters (shaping calls, rebuilds,
allocations, GL flushes, live memory). Counters do not depend on CPU speed or
VSync, so this can gate regressions where frame times cannot. Exit 77 (CTest
SKIP) when no X display or Xvfb is available.

Budgets are ratchets: when an optimization lowers a counter, lower its budget
here in the same change. Values were taken from Debug runs on
2026-11-17 / 2026-11-18 (see docs/performans_analizi.md) with ~10% headroom.
"""
import os
import shutil
import subprocess
import sys
import tempfile
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools/performance"))
import summarize  # noqa: E402

SKIP = 77
# (label, metric, statistic, maximum)
DOCUMENT_BUDGETS = [
    # First frame shapes only the viewport band (visible-first wrap, 2026-11-18);
    # the rest is shaped in "background" frames before warm_idle.
    ("first", "counter.wrap_builds", "max", 1),
    ("first", "counter.layout_builds", "max", 1),        # full layout over placeholders
    ("first", "counter.layout_updates", "max", 2),       # 1 today: incremental after band shaping
    ("first", "counter.wrap_lines", "max", 16),          # 13 today (was all 1296 lines)
    ("first", "counter.shape_calls", "max", 48),         # 40 today (was 824)
    ("first", "counter.alloc_calls", "max", 94_000),     # 85,049 today (was 173,073)
    ("first", "counter.gl_flush_calls", "max", 100),     # 91 today; atlas uploads flush
    ("background", "counter.wrap_builds", "max", 0),     # no rebuild while draining
    ("background", "counter.layout_builds", "max", 0),   # incremental only
    ("background", "counter.layout_updates", "max", 1),
    ("warm_idle", "counter.wrap_lines", "max", 0),       # background fully drained
    ("warm_idle", "counter.shape_calls", "max", 0),
    ("warm_idle", "counter.wrap_builds", "max", 0),
    ("warm_idle", "counter.layout_builds", "max", 0),
    ("warm_idle", "counter.alloc_calls", "max", 32),     # 12 today
    ("warm_idle", "counter.gl_flush_calls", "max", 22),  # 20 today
    ("warm_scroll_wheel", "counter.wrap_builds", "max", 0),
    ("warm_scroll_wheel", "counter.layout_builds", "max", 0),
    ("warm_scroll_wheel", "counter.shape_calls", "median", 2),   # 1 today
    ("warm_scroll_wheel", "counter.shape_calls", "p95", 6),      # 4 today
    ("warm_scroll_wheel", "counter.alloc_calls", "p95", 250),    # 222 today with the shape-plan cache (was 465)
]
SEARCH_BUDGETS = [
    ("search", "counter.alloc_calls", "max", 1_200),     # 1,079 today for 50 notes
    ("search", "counter.document_loads", "max", 0),
    ("search", "counter.ast_parses", "max", 0),
]


def start_xvfb(env):
    xvfb = shutil.which("Xvfb")
    if not xvfb:
        return None
    for number in range(91, 99):
        if Path(f"/tmp/.X11-unix/X{number}").exists():
            continue
        proc = subprocess.Popen([xvfb, f":{number}", "-screen", "0", "1280x800x24", "-nolisten", "tcp"],
                                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        for _ in range(50):
            if Path(f"/tmp/.X11-unix/X{number}").exists():
                env["DISPLAY"] = f":{number}"
                return proc
            if proc.poll() is not None:
                break
            time.sleep(0.1)
        proc.kill()
    return None


def run_document(binary, fixture, env):
    return subprocess.run([binary, str(fixture / "vault"), str(fixture / "heavy.md"), "read", "wheel"],
                          capture_output=True, text=True, env=env, timeout=600)


def check(summary, budgets, failures):
    for label, metric, statistic, maximum in budgets:
        stats = summary.get(label, {}).get(metric)
        if stats is None:
            failures.append(f"{label} {metric}: missing")
            continue
        value = stats[statistic]
        status = "ok" if value <= maximum else "OVER"
        print(f"budget {status} {label} {metric} {statistic}={value:g} limit={maximum:g}")
        if value > maximum:
            failures.append(f"{label} {metric} {statistic}={value:g} > {maximum:g}")


def main():
    if len(sys.argv) != 3:
        print(__doc__, file=sys.stderr)
        return 2
    document, search = sys.argv[1:]
    env = dict(os.environ)
    env.pop("ANTHRACITE_PERF_PROFILE", None)
    env.pop("ANTHRACITE_PERF_LOG", None)
    xvfb = None
    with tempfile.TemporaryDirectory(prefix="anthracite-perf-budget-") as root:
        fixture = Path(root)
        subprocess.run([sys.executable, str(ROOT / "tools/performance/gen_fixture.py"), str(fixture)],
                       check=True, stdout=subprocess.DEVNULL)
        try:
            result = run_document(document, fixture, env) if env.get("DISPLAY") else None
            if result is None or "event=benchmark_context" not in result.stdout:
                xvfb = start_xvfb(env)
                if xvfb is None:
                    print("SKIP: no usable X display and no Xvfb")
                    return SKIP
                result = run_document(document, fixture, env)
            if result.returncode != 0:
                print(result.stdout[-4000:], result.stderr[-4000:], sep="\n")
                print(f"document_performance failed with {result.returncode}")
                return 1
            # Counter budgets need the deterministic sequential search; the
            # parallel search is checked for equality in parallel_search_contracts
            # and here only for leaks.
            sequential = dict(env, ANTHRACITE_PARALLEL_SEARCH="0")
            search_result = subprocess.run([search, str(fixture / "vault"), "not", "5"],
                                           capture_output=True, text=True, env=sequential, timeout=300, check=False)
            parallel_result = subprocess.run([search, str(fixture / "vault"), "not", "5"],
                                             capture_output=True, text=True, env=env, timeout=300, check=False)
        finally:
            if xvfb is not None:
                xvfb.terminate()
                xvfb.wait(timeout=10)
        if search_result.returncode != 0:
            print(search_result.stdout, search_result.stderr, sep="\n")
            return 1
        doc_log = fixture / "document.log"
        doc_log.write_text(result.stdout)
        search_log = fixture / "search.log"
        search_log.write_text(search_result.stdout)
        failures = []
        check(summarize.summarize(summarize.parse([doc_log])), DOCUMENT_BUDGETS, failures)
        check(summarize.summarize(summarize.parse([search_log])), SEARCH_BUDGETS, failures)
        if "live_delta=0" not in search_result.stdout:
            failures.append("search leaked live allocations: " + search_result.stdout.splitlines()[-1])
        if parallel_result.returncode != 0 or "live_delta=0" not in parallel_result.stdout:
            failures.append("parallel search leaked or failed: " + (parallel_result.stdout.splitlines() or ["no output"])[-1])
        alloc_runs = {line.split("alloc_calls=")[1].split()[0]
                      for line in search_result.stdout.splitlines() if "alloc_calls=" in line}
        if len(alloc_runs) != 1:
            failures.append(f"search allocations differ between identical runs: {sorted(alloc_runs)}")
    for failure in failures:
        print("FAIL", failure)
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
