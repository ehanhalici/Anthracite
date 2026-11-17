"""CLI contracts for fresh-process medians and phase-separated nearest-rank p95."""
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

SUMMARY = Path(__file__).resolve().parents[2] / "tools/performance/summarize.py"


class PerformanceSummaryTests(unittest.TestCase):
    def summarize(self, *logs, extra=()):
        with tempfile.TemporaryDirectory(prefix="anthracite-summary-") as root:
            paths = []
            for index, contents in enumerate(logs):
                path = Path(root) / f"run-{index}.log"
                path.write_text(contents)
                paths.append(str(path))
            return subprocess.run(
                [sys.executable, str(SUMMARY), *extra, *paths],
                capture_output=True, text=True, check=False,
            )

    def test_fresh_process_first_frame_median(self):
        result = self.summarize(
            "event=document_frame sample=0 elapsed_ns=10000000 phase=first\n",
            "event=document_frame sample=0 elapsed_ns=20000000 phase=first\n",
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("phase=first samples=2 median_ms=15.000 p95_ms=20.000", result.stdout)

    def test_prewarm_does_not_pollute_warm_scroll(self):
        result = self.summarize(
            "unrelated diagnostic\n"
            "event=document_frame sample=63 elapsed_ns=900000000 phase=prewarm_scroll\n"
            "event=document_frame sample=3 elapsed_ns=5000000 phase=warm_scroll\n"
            "event=document_frame sample=4 elapsed_ns=7000000 phase=warm_scroll\n"
            "event=document_frame sample=1 elapsed_ns=1000000 phase=warm_idle\n"
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("phase=warm_scroll samples=2 median_ms=6.000 p95_ms=7.000", result.stdout)
        self.assertIn("phase=warm_idle samples=1 median_ms=1.000", result.stdout)

    def test_cpu_split_counters_and_phases_follow_their_frame(self):
        log = (
            "event=performance_counter name=shape_calls value=999\n"  # load report: ignored
            "event=document_frame sample=3 elapsed_ns=16000000 cpu_ns=2000000 gpu_wait_ns=13000000 "
            "swap_ns=1000000 scroll=48 phase=warm_scroll_wheel\n"
            "event=performance_counter name=shape_calls value=2\n"
            "event=perf_phase name=visual_paint calls=3 total_ns=500000 max_ns=1\n"
            "event=perf_phase name=plat_swap calls=0 total_ns=0 max_ns=0\n"
            "event=document_frame sample=4 elapsed_ns=16000000 cpu_ns=4000000 gpu_wait_ns=11000000 "
            "swap_ns=1000000 scroll=96 phase=warm_scroll_wheel\n"
            "event=performance_counter name=shape_calls value=4\n"
        )
        result = self.summarize(log, extra=("--json",))
        self.assertEqual(result.returncode, 0, result.stderr)
        wheel = json.loads(result.stdout)["warm_scroll_wheel"]
        self.assertEqual(wheel["cpu_ms"]["median"], 3.0)
        self.assertEqual(wheel["counter.shape_calls"]["median"], 3)
        self.assertEqual(wheel["counter.shape_calls"]["max"], 4)
        self.assertEqual(wheel["phase.visual_paint_ms"]["samples"], 1)
        self.assertNotIn("phase.plat_swap_ms", wheel)

    def test_search_runs_and_compare(self):
        log = ("event=literal_search_benchmark run=0 elapsed_ns=4000000 rows=2 alloc_calls=10\n"
               "event=literal_search_benchmark run=1 elapsed_ns=2000000 rows=2 alloc_calls=10\n")
        base = self.summarize(log, extra=("--json",))
        self.assertEqual(json.loads(base.stdout)["search"]["elapsed_ms"]["median"], 3.0)
        with tempfile.TemporaryDirectory(prefix="anthracite-summary-") as root:
            path = Path(root) / "base.json"
            path.write_text(base.stdout.replace('"median": 3.0', '"median": 6.0'))
            result = self.summarize(log, extra=("--compare", str(path)))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("phase=search samples=2 median_ms=3.000", result.stdout)

    def test_missing_samples_are_an_error(self):
        result = self.summarize("event=document_load ok=false\n")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("No document_performance frame samples found", result.stderr)


if __name__ == "__main__":
    unittest.main()
