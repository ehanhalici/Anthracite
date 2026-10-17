"""CLI contracts for fresh-process medians and phase-separated nearest-rank p95."""
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

SUMMARY = Path(__file__).resolve().parents[2] / "tools/performance/summarize.py"


class PerformanceSummaryTests(unittest.TestCase):
    def summarize(self, *logs):
        with tempfile.TemporaryDirectory(prefix="anthracite-summary-") as root:
            paths = []
            for index, contents in enumerate(logs):
                path = Path(root) / f"run-{index}.log"
                path.write_text(contents)
                paths.append(str(path))
            return subprocess.run(
                [sys.executable, str(SUMMARY), *paths],
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

    def test_missing_samples_are_an_error(self):
        result = self.summarize("event=document_load ok=false\n")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("No document_performance frame samples found", result.stderr)


if __name__ == "__main__":
    unittest.main()
